# Documentation Maintenance

## Priority Rule

If documentation conflicts with implementation, update documentation to match current code behavior unless the task explicitly requires changing the code.

## Practical Source Hierarchy

1. Current script and library code
2. Recent commit history (for intent and regressions)
3. Existing markdown docs

## Update Triggers

Update docs when changes affect:

- Setup and compatibility prerequisites
- Config keys/defaults/valid values
- Hotkey behavior or naming
- Tray menu commands and script UX
- Known limitations or caveats

## Writing Rules

- Keep instructions concrete and actionable.
- Avoid vague statements (e.g., “follow best practices”).
- Prefer examples grounded in actual `settings.ini` keys and runtime behavior.
- Keep navigation simple with direct links from high-level docs.

## Consistency Checks

Before finalizing documentation edits:

- Ensure claims are aligned with current code paths.
- Ensure linked documents exist and paths are correct.
- Ensure compatibility statements reflect current runtime logic.
