# Windows 11 Virtual Desktop Enhancer

AutoHotkey utility for enhanced virtual desktop management on Windows, with automatic accessor DLL selection for Windows 10/11.

## Quick Reference

- **Runtime:** AutoHotkey v2 script
- **Entrypoint:** `virtual-desktop-enhancer.ahk`
- **Primary config:** `settings.ini`
- **Version source of truth:** `[App] Version` in `settings.ini` (do not hardcode version in script files)
- **Critical behavior override:** when documentation and implementation diverge, treat code and recent commits as source of truth.

## Versioning Policy

- Runtime/app version must be read from `[App] Version` in `settings.ini`.
- `virtual-desktop-enhancer.ahk` should use loaded settings value for `VDE_SCRIPT_VERSION`.
- `CHANGELOG.md` must be kept in reverse chronological order (newest release on top).
- On release bump, update version in `settings.ini` and corresponding release section in `CHANGELOG.md` in the same change set to avoid drift.

## Detailed Instructions

- [Project Context](docs/agent/project-context.md)
- [Code Change Rules](docs/agent/code-changes.md)
- [Configuration & Compatibility](docs/agent/config-and-compatibility.md)
- [Documentation Maintenance](docs/agent/documentation.md)
