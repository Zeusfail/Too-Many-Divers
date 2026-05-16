# Too-Many-Divers
A [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) mod for **Subnautica 2** that removes the default 4-player co-op cap, allowing up to 16 players in a single session.

---

## Versions

| Version | Status | Max Players | SN2ModSettings | Download |
|---|---|---|---|---|
| **Stable** | ✅ Confirmed up to 7 players | 16 (max 64) | ❌ | [Latest Release](https://github.com/Zeusfail/Too-Many-Divers/releases/latest) |
| **Experimental** | ⚠️ Untested | 16 (max 64) | ✅ Live slider | [v1.1.0](https://github.com/Zeusfail/Too-Many-Divers/releases/tag/Expiremental) |

> Always back up your save files before using this mod.

---

# ✅ Stable Version

## Status
Confirmed working up to 7 players. Beyond that is unknown use at your own risk.

The mod does not modify any game files and can be removed at any time by deleting the `TooManyDivers` folder.

## Features
- Raises the co-op player cap from 4 to 16 (configurable up to 64)
- Patches both default objects and live instances
- Hooks `HostSessionAsync` to patch host requests before session start
- Auto-retries hook registration when game systems are not yet ready
- Periodic monitor that re-applies patches if values are reset mid-session

## Requirements
- Subnautica 2 Early Access
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS)

## Installation
1. Download the latest stable release and extract the archive.
2. Navigate to your UE4SS Mods directory:
   - **Steam:** `Subnautica2\Binaries\Win64\ue4ss\Mods\`
   - **Microsoft Store / Game Pass:** `Subnautica2\Binaries\WinGDK\ue4ss\Mods\`
3. Copy the `TooManyDivers` folder directly into `Mods\`:
ue4ss/Mods/TooManyDivers/
   > ⚠️ Do not nest the folder inside another subfolder.
4. Ensure `enabled.txt` exists inside the `TooManyDivers` folder.
5. Launch the game and host a session — the cap is now 16.

---

# ⚠️ Experimental Version (v1.1.0)

**Untested**

## What's new in v1.1.0
- `config/settings.json` for persistent configuration (range: 4–64, default: 16)
- **SN2ModSettings integration** — in-game slider under Settings → Mods
  - Live updates without session restart
  - Manifest auto-written at startup (pre-shipped in ZIP to skip two-launch requirement)
- **Crash fix** — removed `FindAllOf` / `FindFirstOf` calls from async contexts, which caused random access violations in `UObjectBase::IsA` due to stale UObject pointers after GC
- Replaced periodic `FindAllOf` monitor with `apply_cached_patches()` — safe to call from any async context
- Simplified retry logic single +1s CDO-only retry kept for engine warm-up edge cases

## Requirements
- Subnautica 2 Early Access
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS)
- [Mod Settings for Subnautica 2](https://www.nexusmods.com/subnautica2)

## Installation
1. Download the [experimental release](https://github.com/Zeusfail/Too-Many-Divers/releases/tag/Expiremental) and extract the archive.
2. Follow the same folder structure as the stable version.
3. Install **Mod Settings for Subnautica 2** from Nexus Mods.
4. Launch the game — the in-game slider will appear under **Settings → Mods**.

---

## Networking Notes
Since Subnautica 2 uses **P2P networking**, the host handles all connections.
- The host should have a **good internet connection and a powerful CPU**, especially beyond 8 players.
- In theory, only the host needs the mod. However, this has not been confirmed — **install it for everyone** until further notice.
- If you test host-only and it works, please let me know!

---

## Limitations
- Only patches session/player cap values at runtime does not modify any game files.
- Network stability beyond 4 players depends on the game engine and platform infrastructure.
- No guarantee the game will function correctly with a high player count.
- Unexpected crashes or desyncs may still occur, especially with higher player counts ( > 8 ).

---

## Disclaimer
This is an unofficial, community-made mod. Not affiliated with or endorsed by Unknown Worlds Entertainment. **Use at your own risk.**

---

## Contact & Support
💬 Discord — `zeusfail`
☕ [Support the mod](https://buymeacoffee.com/zayla)

Made with love from French Polynesia 🌺

---

## License
MIT License — see [LICENSE](LICENSE) for details.
