# Launcher Worker Task

## Objective

Extend Caelestia's existing launcher with the following capabilities:

- Indexed file search.
- Running-window search.
- An emoji picker.
- A safe command runner.
- A launcher search-provider interface, but only if the implementation truly
  requires one.

## Required approach

- Extend the launcher that already exists in Caelestia; do not create a
  separate DankMaterialShell launcher.
- Preserve Caelestia's codebase, branding, visual style, and existing
  fluid/morphing animation language.
- Keep command execution safe, explicit, and non-blocking.
- Make optional dependencies degrade gracefully when unavailable.
- Build and test all changes before committing.
- Update `INTEGRATION_NOTES.md` with any shared integration or configuration
  requirements.

## Ownership boundaries

- Do not modify the shared config schema.
- If configuration additions are needed, describe them in
  `INTEGRATION_NOTES.md` for the Desktop Integration worker.
- Do not implement clipboard history, process management, Bluetooth, display
  management, notifications, or calendar features.
- Do not work outside the scope above, do not modify another worktree, and do
  not merge another worker's branch.
