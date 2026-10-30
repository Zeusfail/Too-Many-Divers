# Changelog

All notable changes to this project will be documented in this file.

## Too Many Divers - Voice [1.0.0] - 2026-10-30

### Added
- New add-on `TooManyDiversVoice`, to be installed by **every player**: proximity voice chat for up to 9 players.
  The game's voice pool (`UWEVoiceChatWorldSubsystem.ActiveChatAssets`) only holds 3 FMOD slots
  (`player_01/03/04`), so each machine played at most 3 remote voices. The add-on fills the pool with the unused
  slots shipped in the FMOD banks (`player_00..07`, event + VCA). Verified in-game (3 -> 8 slots); not yet tested
  with 5+ real players.
- Settings in `config/settings.json` and SN2ModSettings (Settings → Mods): `Enabled` toggle and
  `MaxVoicePlayers` slider (4 – 9). Applied the next time a game is loaded.

---

## [1.2.1] - 2026-10-30

### Fixed
- The host session request is now patched on its real field, `MaxPlayerCount` (inherited from
  `UCommonSession_HostSessionRequest`); the old `MaxPlayers` / `MaxSessionPlayerCount` names do not exist on that class.
- The request is patched when it is created and again on the next tick, because `HostSessionAsync` is called natively
  and the UE4SS hook on it never fires; that hook has been removed.
- Removed debug log messages; warnings (missing objects, invalid config) are kept.
- README: config key is `MaxPlayers` (not `MAX_PLAYERS`); patched objects table matches the code.

### Compatibility
- Verified loading and patching on Subnautica 2 Early Access 1.2 (Buddy System Hotfix 2, Xbox build 0.13.1439).

---

## [1.2.0] - 2026-05-18

### Added
- **SN2ModSettings Integration**: Max Players setting now available in-game via the Mods tab
  - Slider range: 4-64 players (up from hardcoded 16)
  - Changes apply in real-time without restarting
  - Settings persist across sessions
- **GitHub Release Checks**: Auto-update detection via SN2ModSettings (checked every 3 hours)
- **Nexus Mods Button**: Direct link to mod page in SN2ModSettings UI

### Changed
- Max Players is now configurable via `SN2ModSettings/saved/TooManyDivers.lua` (in addition to `config/settings.json`)
- Description text updated to English in manifest
- Config loading now gracefully falls back to default (16) if not found

### Technical
- Manifest generation improved with `version` and `github` fields
- SharedVariable polling (1s interval) allows live updates from SN2ModSettings
- Added `load_from_shared()` function for runtime config changes
- Cached instance tracking prevents unsafe `FindAllOf` calls in async contexts
- CDO-only patching in delayed hooks for stability

### Fixed
- Removed deprecated monitor loop that caused unnecessary CPU usage
- Improved error handling in config path resolution

---

## [1.0.0] - 2026-05-15

### Added
- Initial public release
- Runtime patching for multiplayer/session cap fields
- HostSessionAsync pre/post hooks
- Retry strategy for delayed engine initialization
- Periodic monitor and auto re-patching
