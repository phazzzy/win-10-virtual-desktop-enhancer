# Changelog

All notable changes to this project will be documented in this file.

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

