# Too-Many-Divers

A UE4SS mod for Subnautica 2 that increases multiplayer session capacity by patching runtime session limits.

## About

Too-Many-Divers forces the game to use a higher player cap (default: 16) by patching:

- SN2GameSession.MaxPlayers
- UWEOnlineSessionSubsystem.MaxSessionPlayerCount
- UWEHostSessionRequest.MaxPlayers
- UWEHostSessionRequest.MaxSessionPlayerCount

The mod retries and monitors values to prevent them from reverting during play.

## Features

- Raises max players to 16
- Patches both default objects and live instances
- Hooks HostSessionAsync to patch host requests before session start
- Auto-retries hook registration when game systems are not ready yet
- Periodic monitor that re-applies patches if values are reset

## Requirements

- Subnautica 2
- UE4SS installed and working

## Installation

1. Copy this folder into your UE4SS mods directory:
   - ue4ss/Mods/MorePlayers
2. Ensure the file enabled.txt exists in the mod folder.
3. Launch the game.

## Configuration

Open Scripts/main.lua and edit this value:

- TARGET_MAX_PLAYERS = 16

Set any number you want, then restart the game.

## Logs and Validation

The mod prints logs tagged with:

- [Too-Many-Divers]

Check your UE4SS log output to confirm patches and hook registration.

## Project Structure

- Scripts/main.lua: runtime patch logic
- enabled.txt: enables the mod

## Limitations

- This only changes session/player cap values at runtime.
- Network stability and gameplay behavior still depend on the game and platform.

## Disclaimer

This is an unofficial mod. Use at your own risk.

## Testing Status

This mod has not been tested in a controlled way.

- No functional test suite has been run.
- We do not know for sure whether it works in every game state.
- Performance impact has not been measured.
- There may be unexpected side effects, instability, or gameplay consequences.

Use it only if you accept the risk of bugs, crashes, or other unintended behavior.

## License

MIT License. See LICENSE.
