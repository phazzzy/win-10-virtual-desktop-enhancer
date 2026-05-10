# Changelog

All notable changes to this project will be documented in this file.

## [2.0.3] - 2026-05-10

### Added
- New `[General]` runtime tuning keys in `settings.ini`:
  - `HotkeyBurstTuningEnabled`
  - `MaxHotkeysPerInterval`
  - `HotkeyIntervalMs`

### Changed
- Wheel scroll hotkeys are now context-gated with `HotIf(...)` in `libraries/hotkey-registrar.ahk`, reducing global wheel handler activations outside taskbar/bottom-edge trigger zones.
- Taskbar/monitor detection path was optimized in `libraries/core-domain.ahk` by caching taskbar window IDs and monitor bounds.
- Wheel route checks were streamlined in `libraries/event-router.ahk` to avoid duplicated cursor-area evaluation in the router layer.
- Startup now applies AutoHotkey burst tuning from loaded settings in `virtual-desktop-enhancer.ahk` via `VdeApplyHotkeyBurstTuning(settings)`.
- Burst tuning application in `virtual-desktop-enhancer.ahk` is now executed inside startup `try/catch`, so runtime assignment errors follow the existing controlled startup failure path.
- `VdeApplyHotkeyBurstTuning(settings)` now clamps hotkey burst runtime values before assignment (`A_MaxHotkeysPerInterval`: `1..1000`, `A_HotkeyInterval`: `1..60000`).
- `libraries/settings-provider.ahk` now loads hotkey burst tuning keys with defensive defaults (`140` / `1000ms`).
- Documentation aligned with current runtime/config behavior:
  - `docs/settings.md`
  - `docs/agent/project-context.md`
  - `docs/agent/code-changes.md`
  - `docs/agent/config-and-compatibility.md`

## [2.0.2] - 2026-05-10

### Added
- Runtime `Settings` submenu toggles in tray menu for:
  - `TaskbarScrollSwitching`
  - `TaskbarScrollBottomEdgeOnly`
  - `UseNativeDesktopSwitching`
  - `DesktopWrapping`
  - `Debug`
  - `Tooltips`

### Changed
- Tray menu structure refactored in `libraries/tray-renderer.ahk`:
  - moved reload/open/edit/exit actions under `Script` submenu
  - centralized menu state sync via `SyncMenuState()`.
- `libraries/event-router.ahk` now applies and persists runtime toggle changes immediately through `VdeSettingsProvider`.
- `libraries/settings-provider.ahk` now includes `SaveBool()` and `SaveInt()` helpers for persisting runtime settings updates.
- `virtual-desktop-enhancer.ahk` now binds tray/router integration explicitly and enables dark tray menu theming with compatibility guards/fallbacks.
- `docs/settings.md` updated with tray runtime toggle behavior documentation.

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
