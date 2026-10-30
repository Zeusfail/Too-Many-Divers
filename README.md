# Too-Many-Divers

> A [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) mod for **Subnautica 2** that removes the default 4-player co-op cap,
> with an optional **Voice** add-on that enables proximity voice chat for up to 9 players.

![License](https://img.shields.io/badge/license-Apache2.0-blue)
![Status](https://img.shields.io/badge/stable-confirmed_16_players-green)
![UE4SS](https://img.shields.io/badge/UE4SS-3.0.1-orange)

---

## Versions

| Version | Status | Max Players | SN2ModSettings | Download |
|---|---|---|---|---|
| **Stable** | ✅ Confirmed up to 9 players | 16 (max 64) | ✅ Live slider | [Latest Release](https://github.com/Zeusfail/Too-Many-Divers/releases/latest) |
| **Voice add-on** | 🧪 Slots verified in-game, not yet tested with 5+ real players | Voice for 9 | ✅ Toggle + slider | [Latest Release](https://github.com/Zeusfail/Too-Many-Divers/releases/latest) |

| Package | Who installs it | What it does |
|---|---|---|
| `TooManyDivers` | **Host only** | Raises the player cap (4 → 16, up to 64) |
| `TooManyDiversVoice` | **Every player** | Proximity voice chat for up to 9 players (game default: 4) |

> 💾 Always back up your save files before using this mod.

---

## How It Works

> 🔒 **No telemetry. No external calls. Fully client-side and open source.**

### Architecture

Too-Many-Divers patches Subnautica 2's session limits **at runtime** using UE4SS — no game files are modified or replaced.

The mod targets four engine objects that control player capacity:

| Object | Field |
|---|---|
| `SN2GameSession` | `MaxPlayers` |
| `UWEOnlineSessionSubsystem` | `MaxSessionPlayerCount` |
| `UWEHostSessionRequest` | `MaxPlayerCount` |
| `GameSession` | `MaxPlayers` |

### Runtime Patching Flow
Game starts
└─► Patch all Class Default Objects (CDOs)
└─► NotifyOnNewObject on UWEHostSessionRequest
└─► Patch MaxPlayerCount on creation and again on the next tick
└─► NotifyOnNewObject
└─► Cache new instances as they are created → patch immediately
└─► Single +1s CDO retry for engine warm-up edge cases

> All patches run on safe game-thread contexts to prevent crashes caused by
> Unreal Engine's garbage collector invalidating object references.

---

## Compatibility

| Component | Tested Version |
|---|---|
| Subnautica 2 | Early Access 1.2 – Buddy System Hotfix 2 (Xbox build 0.13.1439, Oct 2026) |
| UE4SS | 3.0.1 |
| SN2ModSettings | v1.0.10 |
| Platform | Steam, Microsoft Store / Game Pass |

### Known Issues
- Stability beyond 9 players is unknown — no data gathered yet
- Crashes or desyncs may occur at very high player counts (>9)
- Some builds may require adding `[EngineVersionOverride] MajorVersion=5 MinorVersion=4` in UE4SS config
- Without the Voice add-on, each player only hears 3 other players in proximity voice chat (the game ships 3 voice slots) — see the Voice add-on section below

---

## ✅ Stable (v1.2.0)

### What's New in v1.2.0
- Confirmed stable with up to 9 players over 3 hours
- **Host-only confirmed** — clients do not need the mod installed
- `config/settings.json` — persistent config (range: 4–64, default: 16)
- **SN2ModSettings** — live in-game slider under Settings → Mods, no restart needed
- **Crash fix** — removed unsafe async calls that caused access violations after GC
- Compatible with SN2ModSettings v1.0.10

### Features
- Raises the co-op cap from 4 → 16 (configurable up to 64)
- Patches CDOs and live instances
- Retries CDO patching once after engine startup
- Live config update without session restart

### Requirements
- Subnautica 2 Early Access
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) 3.0.1
- [Mod Settings for Subnautica 2](https://www.nexusmods.com/subnautica2/mods/20) *(optional — enables in-game slider)*

### Installation
1. Download the [latest release](https://github.com/Zeusfail/Too-Many-Divers/releases/latest) and extract it
2. Go to your UE4SS Mods folder:
   - **Steam:** `Subnautica2\Binaries\Win64\ue4ss\Mods\`
   - **Game Pass:** `Subnautica2\Binaries\WinGDK\ue4ss\Mods\`
3. Drop the `TooManyDivers` folder directly into `Mods\`
   > ⚠️ Do not nest it inside a subfolder
4. Confirm `enabled.txt` is present inside the folder
5. Launch the game — the cap is now 16

### Configuration
Edit `TooManyDivers/config/settings.json`:
```json
{
  "MaxPlayers": 16
}
```
Valid range: **4 – 64** — changes apply live without restarting the game.

---

## 🎙️ Voice add-on (v1.0.0)

### The problem
Proximity voice chat plays each remote player on a dedicated FMOD slot (event + VCA). The game only declares
**3 slots** (`player_01`, `player_03`, `player_04`), so every machine plays at most 3 remote voices: a 5th player
can join but nobody hears them, and they hear only 3 players.

### The fix
The game's FMOD banks contain **8 slots** (`player_00` → `player_07`). `TooManyDiversVoice` adds the 5 unused ones
to `UWEVoiceChatWorldSubsystem.ActiveChatAssets` as soon as the game fills its pool:

```
[TooManyDiversVoice] Voice pool: 3 -> 8 slots (voice for up to 9 players)
```

### Installation
- **Every player** drops the `TooManyDiversVoice` folder into `Mods\` (same place as `TooManyDivers`)
- A player without it still only hears 3 others
- Works on its own: players who join a host need `TooManyDiversVoice` only, not `TooManyDivers`

### Configuration
`TooManyDiversVoice/config/settings.json`, or **Settings → Mods → Too Many Divers - Voice** with SN2ModSettings:

| Setting | Default | Description |
|---|---|---|
| `Enabled` | `true` | Adds the extra voice slots |
| `MaxVoicePlayers` | `9` | Players who can hear each other (4 – 9, game default 4) |

Changes apply the next time you load a game.

### Limits
- Voice for **9 players max** (8 remote slots). Players beyond the 9th have no in-game voice.
- Slots are verified in-game; not yet confirmed in a real 5+ player session — feedback welcome.

---

## Networking Notes

Subnautica 2 uses **P2P networking** — the host manages all connections.

- **Only the host needs `TooManyDivers`** — confirmed by the community ✅
- For in-game voice chat with 5+ players, **every player needs `TooManyDiversVoice`** — each machine plays the other players' voices itself
- The host should have a **strong CPU and good internet**, especially beyond 8 players
- Tested stable up to 9 players — beyond that, behavior is unknown

---

## Project Structure
TooManyDivers/
├── Scripts/
│   └── main.lua          # Entry point — loaded by UE4SS at startup
├── config/
│   └── settings.json     # Player cap configuration
└── enabled.txt           # Signals UE4SS to load this mod
TooManyDiversVoice/
├── Scripts/
│   └── main.lua          # Adds the missing proximity voice chat slots
├── config/
│   └── settings.json     # Enabled / MaxVoicePlayers
└── enabled.txt
SN2ModSettings/registrations/
├── TooManyDivers.lua      # In-game settings (optional SN2ModSettings)
└── TooManyDiversVoice.lua

---

## FAQ

**Does everyone need to install the mod?**
`TooManyDivers`: only the host. `TooManyDiversVoice`: every player, if you use the in-game voice chat with 5+ players. Groups that use Discord or no voice chat only need `TooManyDivers` on the host.

**Why is voice chat limited to 9 players?**
The game's audio banks only contain 8 voice slots (one per remote player). New slots cannot be created without Unknown Worlds' FMOD project. Players beyond the 9th can still join and play — they just have no in-game voice.

**Is it safe in solo?**
Yes — the mod only affects multiplayer session limits and has no impact on solo play.

**Why do disconnects happen with many players?**
Subnautica 2 uses P2P networking. High player counts put strain on the host's CPU and connection. This is a game engine limitation, not a mod bug.

**Can I remove the mod mid-playthrough?**
Yes — delete the `TooManyDivers` (and `TooManyDiversVoice`) folder. No game files are modified.

**Does the mod send any data externally?**
No. No telemetry, no external calls. Fully client-side and open source.

**“Could not find the UE version?**
Add this to your UE4SS config file:
```ini
[EngineVersionOverride]
MajorVersion=5
MinorVersion=4
```

---

## Limitations

- Runtime patches only — no game files are modified
- Network stability with high player counts depends on the game engine
- No guarantee of correct behavior beyond tested player counts

---

## Disclaimer

Unofficial community mod. Not affiliated with or endorsed by Unknown Worlds Entertainment.
Use at your own risk, particularly in multiplayer environments.

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for full history.

---

## Contact & Support

💬 Discord — `zeusfail`
☕ [Support the mod](https://buymeacoffee.com/zayla)
🔗 [Source Code](https://github.com/Zeusfail/Too-Many-Divers)

Made with love from French Polynesia 🌺
## License

Apache 2.0 — see [LICENSE](LICENSE) for details.

---

## AI disclosure

[![AI assistance: level 2/5](https://img.shields.io/badge/AI_assistance-level_2%2F5-blue)](https://github.com/Zeusfail/Zeusfail/blob/main/AI-CHARTER.md)

Built with AI assistance (Qwen 3.6, level 2/5). The AI reviewed the code, added tests and robustness checks, and rewrote parts of it for readability; the original code and the Subnautica 2 data research are mine. Reviewed and validated by Zayla (Zeusfail). Details: [AI transparency charter](https://github.com/Zeusfail/Zeusfail/blob/main/AI-CHARTER.md).
