# Changelog

All notable changes to this project will be documented in this file.

## [2.0.1] - 2026-05-09

### Added
- Runtime logger module: `libraries/logger.ahk`.
- Debug settings in `settings.ini`:
  - `[Debug] Enabled=0`
  - `[Debug] Verbose=0`

### Changed
- Startup flow in `virtual-desktop-enhancer.ahk` now logs bootstrap phases and wraps initialization in `try/catch` with user-facing failure notification.
- `libraries/settings-provider.ahk` now reads debug configuration flags.
- `libraries/accessor-gateway.ahk` now supports graceful degradation when DLL load/proc binding fails, with structured logging.
- `libraries/hotkey-registrar.ahk` now logs invalid hotkeys and continues registration instead of failing startup.
- `libraries/event-router.ahk`, `libraries/core-domain.ahk`, and `libraries/tray-renderer.ahk` now emit operational logs for key runtime events.

## [2.0.0] - 2026-05-09

### Added
- New AutoHotkey v2 modular runtime architecture with dedicated components:
  - accessor gateway (`libraries/accessor-gateway.ahk`)
  - app state container (`libraries/app-state.ahk`)
  - core desktop domain logic (`libraries/core-domain.ahk`)
  - event router (`libraries/event-router.ahk`)
  - hotkey registrar (`libraries/hotkey-registrar.ahk`)
  - settings provider (`libraries/settings-provider.ahk`)
  - tray renderer (`libraries/tray-renderer.ahk`)
- New script version constant for release/change tracking in `virtual-desktop-enhancer.ahk`.

### Changed
- Main entrypoint `virtual-desktop-enhancer.ahk` migrated to AutoHotkey v2 and rewired to class-based modules.
- Agent/runtime documentation updated for v2 runtime context:
  - `AGENTS.md`
  - `docs/agent/project-context.md`
- Prebuilt binary `virtual-desktop-enhancer.exe` updated.

### Removed
- Legacy monolithic modules removed:
  - `libraries/core.ahk`
  - `libraries/read-ini.ahk`
  - `libraries/tooltip.ahk`
