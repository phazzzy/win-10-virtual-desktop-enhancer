# Project Context

## Overview

Windows 10 Virtual Desktop Enhancer is an AutoHotkey v1 utility that extends Windows virtual desktop workflows with keyboard shortcuts, tray UX, tooltip UX, per-desktop metadata, and optional automation hooks.

## Source of Truth

When repository documentation and implementation diverge, prefer behavior defined in script code and recent commit history.

- Runtime behavior is defined primarily in `virtual-desktop-enhancer.ahk`.
- Compatibility and feature intent can be inferred from recent commits.

## Runtime Architecture

- Entrypoint script: `virtual-desktop-enhancer.ahk`
- Supporting libraries:
  - `libraries/core.ahk`
  - `libraries/read-ini.ahk`
  - `libraries/tooltip.ahk`
- Native integration layer:
  - `libraries/virtual-desktop-accessor/win-10.dll`
  - `libraries/virtual-desktop-accessor/win-11.dll`

## OS Compatibility

The script auto-detects Windows build and selects the appropriate accessor DLL at startup:

- Windows 10 builds use `win-10.dll`
- Windows 11 builds use `win-11.dll`

This compatibility behavior is implemented in code and reinforced by recent commits.

## Primary User Configuration

Main configuration file: `settings.ini`

Key configurable domains include:

- Desktop switching behavior
- Shortcut mappings
- Tooltip behavior
- Desktop names and wallpapers
- Tray icon/theme options
- Hooks for running programs on desktop switches
