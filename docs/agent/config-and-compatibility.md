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

## User-Facing Stability

- Existing tray actions should continue to function.
- Existing hotkey definitions should remain valid unless intentionally changed.
- Existing desktop naming/wallpaper workflows should remain compatible.
