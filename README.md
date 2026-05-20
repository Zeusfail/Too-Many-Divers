# Too-Many-Divers

> A [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) mod for **Subnautica 2** that removes the default 4-player co-op cap.

![License](https://img.shields.io/badge/license-Apache2.0-blue)
![Status](https://img.shields.io/badge/stable-confirmed_16_players-green)
![UE4SS](https://img.shields.io/badge/UE4SS-3.0.1-orange)

---

## Versions

| Version | Status | Max Players | SN2ModSettings | Download |
|---|---|---|---|---|
| **Stable** | ✅ Confirmed up to 9 players | 16 (max 64) | ✅ Live slider | [Latest Release](https://github.com/Zeusfail/Too-Many-Divers/releases/latest) |

> 💾 Always back up your save files before using this mod.

---

## How It Works

> 🔒 **No telemetry. No external calls. Fully client-side and open source.**

### Architecture

Too-Many-Divers patches Subnautica 2's session limits **at runtime** using UE4SS hooks — no game files are modified or replaced.

The mod targets six engine objects that control player capacity:

| Object | Field |
|---|---|
| `SN2GameSession` | `MaxPlayers` |
| `UWEOnlineSessionSubsystem` | `MaxSessionPlayerCount` |
| `UWEHostSessionRequest` | `MaxPlayers`, `MaxSessionPlayerCount` |
| `UWEMultiplayerHostedSessionViewModel` | `MaxPlayers` |
| `GameSession` | `MaxPlayers` |

### Runtime Patching Flow
Game starts
└─► Patch all Class Default Objects (CDOs)
└─► Hook HostSessionAsync
└─► Intercept session creation → patch values before session starts
└─► NotifyOnNewObject
└─► Cache new instances as they are created → patch immediately
└─► Single +1s CDO retry for engine warm-up edge cases

> All patches run on safe game-thread contexts to prevent crashes caused by
> Unreal Engine's garbage collector invalidating object references.

---

## Compatibility

| Component | Tested Version |
|---|---|
| Subnautica 2 | Early Access (May 2026) |
| UE4SS | 3.0.1 |
| SN2ModSettings | v1.0.10 |
| Platform | Steam, Microsoft Store / Game Pass |

### Known Issues
- Stability beyond 9 players is unknown — no data gathered yet
- Crashes or desyncs may occur at very high player counts (>9)
- Some builds may require adding `[EngineVersionOverride] MajorVersion=5 MinorVersion=4` in UE4SS config

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
- Auto-retries hook registration on engine startup
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
  "MAX_PLAYERS": 16
}
```
Valid range: **4 – 64** — changes apply live without restarting the game.

---

## Networking Notes

Subnautica 2 uses **P2P networking** — the host manages all connections.

- **Only the host needs the mod** — confirmed by the community ✅
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

---

## FAQ

**Does everyone need to install the mod?**
No — only the host needs it. Confirmed by the community.

**Is it safe in solo?**
Yes — the mod only affects multiplayer session limits and has no impact on solo play.

**Why do disconnects happen with many players?**
Subnautica 2 uses P2P networking. High player counts put strain on the host's CPU and connection. This is a game engine limitation, not a mod bug.

**Can I remove the mod mid-playthrough?**
Yes — delete the `TooManyDivers` folder. No game files are modified.

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
