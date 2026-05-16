# Too-Many-Divers

> A [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) mod for **Subnautica 2** that removes the default 4-player co-op cap.

![License](https://img.shields.io/badge/license-MIT-blue)
![Status](https://img.shields.io/badge/stable-confirmed_7_players-green)
![UE4SS](https://img.shields.io/badge/UE4SS-required-orange)

---

## Versions

| Version | Status | Max Players | SN2ModSettings | Download |
|---|---|---|---|---|
| **Stable** | ✅ Confirmed up to 7 players | 16 (max 64) | ❌ | [Latest Release](https://github.com/Zeusfail/Too-Many-Divers/releases/latest) |
| **Experimental** | ⚠️ Untested | 16 (max 64) | ✅ Live slider | [v1.1.0](https://github.com/Zeusfail/Too-Many-Divers/releases/tag/Experimental) |

> 💾 Always back up your save files before using this mod.

---

## How It Works

> 🔒 **No telemetry. No external calls. Fully client-side and open source.**

### Architecture

Too-Many-Divers patches Subnautica 2's session limits **at runtime** using UE4SS hooks no game files are modified or replaced.

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

└─► Periodic monitor

└─► Re-apply patches if the game resets any value mid-session

> All patches run on safe game-thread contexts to prevent crashes caused by
> Unreal Engine's garbage collector invalidating object references.

---

## Compatibility

| Component | Tested Version |
|---|---|
| Subnautica 2 | Early Access (May 2026) |
| UE4SS | 3.0.1 |
| Platform | Steam, Microsoft Store / Game Pass, (searching for tester on other platform) |

### Known Issues
- Stability beyond 7 players is unknown no data gathered yet
- Crashes or desyncs may occur at high player counts (>8)
- Host-only mode (clients without the mod) is not yet confirmed working

---

# ✅ Stable

### Features
- Raises the co-op cap from 4 → 16 (configurable up to 64)
- Patches CDOs and live instances
- Auto-retries hook registration on engine startup
- Periodic re-patch monitor for mid-session resets

### Requirements
- Subnautica 2 Early Access
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS)

### Installation
1. Download the [latest release](https://github.com/Zeusfail/Too-Many-Divers/releases/latest) and extract it
2. Go to your UE4SS Mods folder:
   - **Steam:** `Subnautica2\Binaries\Win64\ue4ss\Mods\`
   - **Game Pass:** `Subnautica2\Binaries\WinGDK\ue4ss\Mods\`
3. Drop the `TooManyDivers` folder directly into `Mods\`
   > ⚠️ Do not nest it inside a subfolder
4. Confirm `enabled.txt` is present inside the folder
5. Launch the game the cap is now 16

---

# ⚠️ Experimental (v1.1.0)

**Untested. Not recommended for regular play.**

### What's New
- `config/settings.json` persistent config (range: 4–64, default: 16)
- **SN2ModSettings** live in-game slider under Settings → Mods, no restart needed
- **Crash fix** removed unsafe `FindAllOf` / `FindFirstOf` calls from async contexts
  - Root cause: stale object references accessed after garbage collection, causing access violations
  - *In plain terms: this prevents random crashes caused by Unreal Engine cleaning up memory mid-operation*
- Replaced `FindAllOf` monitor with `apply_cached_patches()` safe to call from any async context
- Simplified retry logic single +1s CDO retry for engine warm-up edge cases

### Requirements
- Subnautica 2 Early Access
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS)
- [Mod Settings for Subnautica 2](https://www.nexusmods.com/subnautica2)

### Installation
1. Download the [experimental release](https://github.com/Zeusfail/Too-Many-Divers/releases/tag/Experimental) and extract it
2. Follow the same folder structure as the stable version
3. Install **Mod Settings for Subnautica 2** from Nexus Mods
4. Launch the game the slider appears under **Settings → Mods**

---

## Networking Notes

Subnautica 2 uses **P2P networking** the host manages all connections.

- The host should have a **strong CPU and good internet**, especially beyond 8 players
- Only the host needs the mod in theory but this is **not yet confirmed**
- Until confirmed: install the mod on all clients
- Tested with 7 players beyond that, behavior is unknown

---

## FAQ

**Does everyone need to install the mod?**
Officially, only the host needs it. In practice, install it on all clients until host-only is confirmed working.

**Is it safe in solo?**
Yes the mod only affects multiplayer session limits and has no impact on solo play.

**Why does it crash above 8 players?**
Subnautica 2 uses P2P networking. High player counts put strain on the host's CPU and connection. This is a game engine limitation, not a mod bug.

**Can I remove the mod mid-playthrough?**
Yes delete the `TooManyDivers` folder. No game files are modified.

**Does the mod send any data externally?**
No. No telemetry, no external calls. Fully client-side and open source.

---

## Limitations

- Runtime patches only no game files are modified
- Network stability with high player counts depends on the game engine
- No guarantee of correct behavior beyond tested player counts
- Crashes or desyncs may still occur, especially above 8 players

---

## Disclaimer

Unofficial community mod. Not affiliated with or endorsed by Unknown Worlds Entertainment.

---

## Contact & Support

💬 Discord `zeusfail`
☕ [Support the mod](https://buymeacoffee.com/zayla)

Made with love from French Polynesia 🌺

---

## License

MIT see [LICENSE](LICENSE) for details.
