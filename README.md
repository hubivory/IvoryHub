# Ivory Hub

Multi-game script loader for Roblox, powered by ObsidianUltra UI library.

## Features

- **Multi-Game Support**: Load scripts for different games from one hub
- **Script Management**: Toggle scripts on/off with a clean UI
- **Auto-Detection**: Automatically detects which game you're playing
- **Config Saving**: Remembers your preferences

## Supported Games

| Game | Place ID | Scripts |
|------|----------|---------|
| Final Swarm [Skills] | 85776757589518 | Auto Dodge + Float Kill |

## Setup

1. Copy `IvoryHub.luau` to your executor
2. The hub will auto-detect your current game
3. Toggle scripts from the Scripts tab

## Adding New Games

Add entries to `GameRegistry` in `IvoryHub.luau`:

```lua
[PLACE_ID] = {
    Name = "Game Name",
    Icon = "gamepad",
    Scripts = {
        {
            Name = "Script Name",
            File = "games/ScriptName.luau",
            Description = "Description"
        }
    }
}
```

## Repository Structure

```
IvoryHub/
├── IvoryHub.luau          # Main loader script
├── games/
│   └── FinalSwarm.luau    # Final Swarm auto-dodge
├── UI_STYLE.json          # UI configuration
└── README.md
```

## Usage

```lua
-- Load the hub
loadstring(game:HttpGet("https://raw.githubusercontent.com/hubivory/IvoryHub/main/IvoryHub.luau"))()
```

## Credits

- UI Library: [ObsidianUltra](https://github.com/joustingmatch/ObsidianUltra)
- Hub: [hubivory](https://github.com/hubivory)
