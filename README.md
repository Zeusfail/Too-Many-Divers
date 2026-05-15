# Too-Many-Divers

A [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) mod for **Subnautica 2** that increases multiplayer session capacity by patching runtime session limits.

---

## ⚠️ Testing Status

**This mod has not been thoroughly tested.**

- No formal test suite has been run
- Behavior in all game states is not guaranteed
- Performance impact has not been measured
- Instability, crashes, or unexpected side effects may occur

> Use it only if you accept the risk of bugs, crashes, or unintended behavior.

---

## About


Too-Many-Divers raises the game's player cap (default: **16**) by patching the following at runtime:

- `SN2GameSession.MaxPlayers`
- `UWEOnlineSessionSubsystem.MaxSessionPlayerCount`
- `UWEHostSessionRequest.MaxPlayers`
- `UWEHostSessionRequest.MaxSessionPlayerCount`
- `UWEMultiplayerHostedSessionViewModel.MaxPlayers`
- `GameSession.MaxPlayers`

The mod continuously monitors these values and re-applies patches if they are reset by the game.

---


## Features

- Raises the max player count to 16 (configurable)
- Patches both default objects and live instances
- Hooks `HostSessionAsync` to patch host requests before session start
- Auto-retries hook registration when game systems are not yet ready
- Periodic monitor that re-applies patches if values are reset mid-session

---

## Requirements

- Subnautica 2
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) installed and working

---

## Installation

1. Download the latest release and extract the archive.
2. Navigate to your Subnautica 2 installation folder, then go to the UE4SS mods directory:
   - **Steam:** `Subnautica2\Binaries\Win64\ue4ss\Mods\`
   - **Microsoft Store / Game Pass:** `Subnautica2\Binaries\WinGDK\ue4ss\Mods\`
3. Copy the `TooManyDivers` folder into that directory:
   ```
   ue4ss/Mods/TooManyDivers/
   ```
   > ⚠️ The mod folder must be placed **directly** inside `Mods\` — not inside a subfolder.
4. Ensure the file `enabled.txt` exists inside the `TooManyDivers` folder.
5. Launch the game.

---

## Configuration

Open `Scripts/main.lua` and edit the following value:

```lua
TARGET_MAX_PLAYERS = 16
```

Set it to any number you want, then restart the game.

---

## Logs & Validation

All mod output is tagged with `[Too-Many-Divers]` in the UE4SS log.

Check your UE4SS log file to confirm that patches and hook registration are working correctly.

---

## Project Structure

```
TooManyDivers/
├── Scripts/
│   └── main.lua      # Runtime patch logic
└── enabled.txt       # Enables the mod in UE4SS
```

---

## Limitations

- Only patches session/player cap values at runtime — it does not modify game files.
- Network stability and gameplay behavior beyond 4 players depend on the game engine and platform infrastructure.
- There is no guarantee the game will function correctly with a high player count.

---

## Disclaimer

This is an unofficial, community-made mod. It is not affiliated with or endorsed by Unknown Worlds Entertainment. **Use at your own risk.**

---

## License

MIT License — see [LICENSE](LICENSE) for details.
