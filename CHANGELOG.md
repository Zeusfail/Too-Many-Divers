# Changelog

All notable changes to this project will be documented in this file.

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
