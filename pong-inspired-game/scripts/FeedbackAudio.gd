extends Node

const SETTINGS_PATH := "user://feedback_settings.cfg"
const EFFECT_POOL_SIZE := 12
const UI_POOL_SIZE := 4
const AUDIO_ROOT := "res://assets/audio/"

var effects_volume := 0.62
var music_volume := 0.28
var ui_volume := 0.55
var master_volume := 0.85
var effects_muted := false
var music_muted := false
var ui_muted := false
var master_muted := false
var visual_intensity := 0.8
var screen_shake_enabled := true

var _sfx_players: Array[AudioStreamPlayer] = []
var _ui_players: Array[AudioStreamPlayer] = []
var _sfx_cursor := 0
var _ui_cursor := 0
var _music_player: AudioStreamPlayer
var _music_unlocked := false
var _pending_music := false
var _streams: Dictionary = {}
var _ability_files := ["ability_01", "ability_02", "ability_03", "ability_04", "ability_05", "ability_06", "ability_07", "ability_08", "ability_09", "ability_10"]

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_ensure_bus("UI")
	_load_settings()
	for key in ["paddle_hit", "wall_ping", "speed_impact", "score", "level_start", "level_transition", "level_complete", "victory", "bumper", "ui_hover", "ui_select", "ui_press", "pause", "resume"] + _ability_files:
		_streams[key] = load(AUDIO_ROOT + key + ".wav")
	for i in EFFECT_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	for i in UI_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "UI"
		add_child(p)
		_ui_players.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.volume_db = -80.0
	add_child(_music_player)
	var music: AudioStream = _streams.get("arcade_loop")
	if music == null:
		music = load(AUDIO_ROOT + "arcade_loop.wav")
	if music is AudioStreamWAV:
		music.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_music_player.stream = music
		_music_player.finished.connect(_on_music_finished)
	_apply_volumes()

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus(AudioServer.bus_count)
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		unlock_audio()
	elif event is InputEventMouseButton and event.pressed:
		unlock_audio()
	elif event is InputEventScreenTouch and event.pressed:
		unlock_audio()

func unlock_audio() -> void:
	_music_unlocked = true
	if not _music_player.playing and _music_player.stream != null:
		_music_player.volume_db = -80.0
		_music_player.play()
		var t := create_tween()
		t.tween_property(_music_player, "volume_db", 0.0, 0.8)
	_pending_music = false

func _on_music_finished() -> void:
	if _music_unlocked and not music_muted and music_volume > 0.001:
		_music_player.play()

func _play(name: String, volume: float = 0.55, pitch: float = 1.0, is_ui: bool = false) -> void:
	var stream: AudioStream = _streams.get(name)
	if stream == null:
		return
	var pool := _ui_players if is_ui else _sfx_players
	if pool.is_empty():
		return
	var index: int
	if is_ui:
		index = _ui_cursor
		_ui_cursor = (_ui_cursor + 1) % pool.size()
	else:
		index = _sfx_cursor
		_sfx_cursor = (_sfx_cursor + 1) % pool.size()
	var player := pool[index]
	player.stop()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = linear_to_db(clampf(volume, 0.001, 1.0))
	player.play()

func play_hit(speed_ratio: float, kind: StringName = &"paddle") -> void:
	var fast := speed_ratio >= 0.72
	_play("speed_impact" if fast else ("wall_ping" if kind == &"wall" else "paddle_hit"), lerpf(0.35, 0.78, clampf(speed_ratio, 0.0, 1.0)), randf_range(0.96, 1.04))

func play_bumper() -> void:
	_play("bumper", 0.58, randf_range(0.97, 1.03))

func play_ability(ability_id: int, _speed_ratio: float) -> void:
	var idx := clampi(ability_id, 1, 10)
	_play(_ability_files[idx - 1], 0.48, randf_range(0.98, 1.02))

func play_score(_player: int) -> void:
	_play("score", 0.65, randf_range(0.98, 1.02))

func play_level_start() -> void:
	_play("level_start", 0.52)

func play_transition() -> void:
	_play("level_transition", 0.42)

func play_level_complete() -> void:
	_play("level_complete", 0.65)

func play_victory() -> void:
	_play("victory", 0.72)

func play_ui(name: String = "ui_select") -> void:
	_play(name, 0.3, randf_range(0.98, 1.02), true)

func set_bus_volume(bus_name: String, value: float) -> void:
	var v := clampf(value, 0.0, 1.0)
	match bus_name:
		"Master": master_volume = v
		"Music": music_volume = v
		"SFX": effects_volume = v
		"UI": ui_volume = v
	_apply_volumes()
	_save_settings()

func set_bus_muted(bus_name: String, value: bool) -> void:
	match bus_name:
		"Master": master_muted = value
		"Music": music_muted = value
		"SFX": effects_muted = value
		"UI": ui_muted = value
	_apply_volumes()
	_save_settings()

func set_effects_volume(value: float) -> void:
	set_bus_volume("SFX", value)

func set_visual_intensity(value: float) -> void:
	visual_intensity = clampf(value, 0.0, 1.0)
	_save_settings()

func set_screen_shake_enabled(enabled: bool) -> void:
	screen_shake_enabled = enabled
	_save_settings()

func _apply_volumes() -> void:
	_set_bus("Master", master_volume, master_muted)
	_set_bus("Music", music_volume, music_muted)
	_set_bus("SFX", effects_volume, effects_muted)
	_set_bus("UI", ui_volume, ui_muted)
	if _music_player != null and _music_player.playing:
		var target := linear_to_db(maxf(music_volume, 0.001)) if not music_muted else -80.0
		_music_player.volume_db = target

func _set_bus(name: String, value: float, muted: bool) -> void:
	var idx := AudioServer.get_bus_index(name)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted or value <= 0.001)
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.001)))

func _load_settings() -> void:
	var c := ConfigFile.new()
	if c.load(SETTINGS_PATH) != OK:
		return
	master_volume = float(c.get_value("audio", "master", master_volume))
	music_volume = float(c.get_value("audio", "music", music_volume))
	effects_volume = float(c.get_value("audio", "sfx", effects_volume))
	ui_volume = float(c.get_value("audio", "ui", ui_volume))
	master_muted = bool(c.get_value("audio", "master_muted", master_muted))
	music_muted = bool(c.get_value("audio", "music_muted", music_muted))
	effects_muted = bool(c.get_value("audio", "sfx_muted", effects_muted))
	ui_muted = bool(c.get_value("audio", "ui_muted", ui_muted))
	visual_intensity = float(c.get_value("feedback", "visual_intensity", visual_intensity))
	screen_shake_enabled = bool(c.get_value("feedback", "screen_shake", screen_shake_enabled))

func _save_settings() -> void:
	var c := ConfigFile.new()
	c.set_value("audio", "master", master_volume)
	c.set_value("audio", "music", music_volume)
	c.set_value("audio", "sfx", effects_volume)
	c.set_value("audio", "ui", ui_volume)
	c.set_value("audio", "master_muted", master_muted)
	c.set_value("audio", "music_muted", music_muted)
	c.set_value("audio", "sfx_muted", effects_muted)
	c.set_value("audio", "ui_muted", ui_muted)
	c.set_value("feedback", "visual_intensity", visual_intensity)
	c.set_value("feedback", "screen_shake", screen_shake_enabled)
	c.save(SETTINGS_PATH)
