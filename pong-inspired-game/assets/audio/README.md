# Original audio library

All WAV files in this directory were generated specifically for this project with original procedural synthesis. No external recordings, samples, or third-party assets were used; there are no external asset licenses to track.

- `arcade_loop.wav`: 16-bar, stereo synth groove designed to loop at 108 BPM.
- `paddle_hit.wav`, `wall_ping.wav`, `speed_impact.wav`, `bumper.wav`: gameplay impact cues.
- `ability_01.wav`–`ability_10.wav`: distinct short signatures, mapped to the existing level/CPU ability IDs.
- `score.wav`, `level_start.wav`, `level_transition.wav`, `level_complete.wav`, `victory.wav`: progression and match feedback.
- `ui_hover.wav`, `ui_select.wav`, `ui_press.wav`, `pause.wav`, `resume.wav`: interface feedback.

Files are mono 22.05 kHz PCM for effects and stereo 22.05 kHz PCM for music. Playback is pooled through the `FeedbackAudio` autoload.
