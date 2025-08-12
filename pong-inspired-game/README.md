# Pong Inspired Game

## Overview
This is a top-down Pong inspired game developed using Godot. The game features a start menu, core gameplay screen, end screen, and options to pause, resume, and quit. It also includes a scoring system with a high score feature.

## Project Structure
The project is organized as follows:

```
pong-inspired-game
├── assets
│   ├── sprites          # Contains sprite images for paddles, ball, and backgrounds
│   └── sounds           # Contains sound files for game events and background music
├── scenes
│   ├── MainMenu.tscn    # Main menu scene for starting the game and accessing options
│   ├── Game.tscn        # Core gameplay scene with paddles, ball, and score display
│   ├── PauseMenu.tscn    # Pause menu scene for resuming or quitting the game
│   ├── EndScreen.tscn    # End screen scene displaying final score and options
│   └── OptionsMenu.tscn   # Options menu scene for adjusting game settings
├── scripts
│   ├── MainMenu.gd      # Script for main menu functionality
│   ├── Game.gd          # Script for core gameplay mechanics
│   ├── PauseMenu.gd     # Script for pause menu functionality
│   ├── EndScreen.gd     # Script for end screen logic
│   └── HighScoreManager.gd # Script for managing high scores
├── project.godot        # Project configuration settings for Godot
└── README.md            # Project documentation
```

## Features
- **Start Menu**: Navigate to start the game, access options, or quit.
- **Gameplay**: Engage in the core gameplay with paddle and ball mechanics.
- **Pause/Resume**: Pause the game and resume when ready.
- **End Screen**: View final scores and high scores after the game ends.
- **High Score System**: Save and load high scores to track player performance.

## Setup Instructions
1. Clone the repository or download the project files.
2. Open the project in Godot.
3. Run the `MainMenu.tscn` scene to start the game.

## Game Rules
- Players control paddles to hit the ball and score points.
- The game ends when a player reaches a predetermined score.
- High scores are saved and displayed on the end screen.

Enjoy playing the game!