# Code Change Rules

## Scope and Safety

- Preserve externally observable behavior unless the task explicitly requests a behavior change.
- Keep public script interfaces and expected side effects stable.
- Prefer minimal, focused edits over broad rewrites.

## Preferred Workflow

1. Understand current behavior in `virtual-desktop-enhancer.ahk` and relevant `libraries/*.ahk` files.
2. Modify the smallest responsible unit.
3. Keep naming and style consistent with existing AutoHotkey v2 conventions used in this repository.
4. Validate that startup, tray actions, hotkeys, and desktop-switch paths remain intact.
5. For any claim about runtime behavior, attach concrete evidence (log lines and command output).

## Change Priorities

- Reliability and regression avoidance first.
- Readability and maintainability second.
- Performance improvements only when neutral-risk or clearly beneficial.

## Do

- Keep configuration compatibility with existing `settings.ini` keys whenever possible.
- Handle missing/invalid config values defensively, following current fallback patterns.
- Preserve existing user-facing commands and tray/menu entry semantics unless asked to change them.
- Keep `docs/settings.md` and `docs/agent/*.md` synchronized when adding/changing runtime config keys.

## Avoid

- Introducing new dependencies without explicit need.
- Renaming configuration keys without migration support.
- Changing keyboard shortcut semantics implicitly.
- Refactoring across unrelated subsystems in a single change.
- Declaring fixes complete without startup/runtime logs.
