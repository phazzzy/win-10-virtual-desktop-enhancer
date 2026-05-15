# Configuration & Compatibility

## Configuration Baseline

Primary configuration file: `settings.ini`.

Treat existing keys as compatibility surface. Changes to key names, meanings, or defaults can break user setups and should be avoided unless explicitly requested.

## Compatibility Rules

- Prefer backward-compatible handling of existing `settings.ini` values.
- If adding new settings, ensure absent values degrade gracefully.
- Keep behavior stable for users running either:
  - `virtual-desktop-enhancer.exe`
  - `virtual-desktop-enhancer.ahk`

## OS and Accessor Selection

The runtime chooses accessor DLL by Windows build number:

- `< 20000` -> `libraries/virtual-desktop-accessor/win-10.dll`
- `>= 20000` -> `libraries/virtual-desktop-accessor/win-11.dll`

Do not hardcode a single OS target in new logic unless required by the task.

## Settings Safety

When editing logic that consumes settings:

- Preserve current fallback behavior for invalid or empty values.
- Keep numeric/string parsing semantics aligned with existing code.
- Avoid silent behavioral shifts in hotkey mapping sections.

### Canonical Setting Types (Current Runtime)

Types below reflect actual parsing in `libraries/settings-provider.ahk`:

- `bool01` -> parsed by `_Bool()` (`"1"` is true, anything else is false)
- `int` -> parsed by `_Int()` (invalid values fall back to default)
- `string` -> parsed by `_Str()` (trimmed)
- `hotkey-mods-string` -> `_Str()` then normalized by `_NormMods()`

#### `[App]`

- `Version` -> `string`

#### `[General]`

- `DefaultDesktop` -> `int`
- `TaskbarScrollSwitching` -> `bool01`
- `TaskbarScrollBottomEdgeOnly` -> `bool01`
- `UseNativeDesktopSwitching` -> `bool01`
- `DesktopWrapping` -> `int`
- `NumberOfCyclableDesktops` -> `int`
- `IconDir` -> `string` (runtime-normalized with trailing `/`, empty => `icons/`)
- `HotkeyBurstTuningEnabled` -> `bool01`
- `MaxHotkeysPerInterval` -> `int`
- `HotkeyIntervalMs` -> `int`

#### `[Debug]`

- `Enabled` -> `bool01`
- `Verbose` -> `bool01`

#### `[Tooltips]`

- `Enabled` -> `bool01`
- `Lifespan` -> `int`

Note: Other tooltip keys currently remain compatibility/user-doc surface in `settings.ini`, but are not consumed by the current runtime loader.

#### `[KeyboardShortcutsModifiers]`

- `SwitchDesktopNum` -> `hotkey-mods-string`
- `SwitchDesktopDir` -> `hotkey-mods-string`
- `MoveWindowToDesktopDir` -> `hotkey-mods-string`
- `MoveWindowAndSwitchToDesktopDir` -> `hotkey-mods-string`

#### `[KeyboardShortcutsIdentifiers]`

- `PreviousDesktop` -> `string`
- `NextDesktop` -> `string`
- `LastActiveDesktop` -> `string`
- `Desktop1..Desktop9` -> `string`
- `DesktopAlt1..DesktopAlt9` -> `string`

#### `[KeyboardShortcutsCombinations]`

- `TogglePinWindow` -> `hotkey-mods-string`
- `TogglePinApp` -> `hotkey-mods-string`
- `TogglePinOnTop` -> `hotkey-mods-string`
- `PinOnTop` -> `hotkey-mods-string`
- `UnpinFromTop` -> `hotkey-mods-string`
- `ChangeDesktopName` -> `hotkey-mods-string`

#### `[DesktopNames]`

- `1..9` -> `string`

#### `[Icons]`

- `1..9` -> `string`

#### `[RunProgramWhenSwitchingToDesktop]`

- `1..9` -> `string`

#### `[RunProgramWhenSwitchingFromDesktop]`

- `1..9` -> `string`

#### `[Wallpapers]`

- `1..9` -> `string` (compatibility/user-doc surface; not consumed by current runtime loader)

When adding new keys, update this section, `docs/settings.md`, and loader logic in `libraries/settings-provider.ahk` together.

## User-Facing Stability

- Existing tray actions should continue to function.
- Existing hotkey definitions should remain valid unless intentionally changed.
- Existing desktop naming/wallpaper workflows should remain compatible.
