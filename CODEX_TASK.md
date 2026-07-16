# Control Center Worker Task

## Objective

Extend Caelestia's existing control surfaces and services with:

- A Bluetooth manager.
- Audio input and output routing.
- Microphone controls.
- Audio device and profile selection.
- A display manager for Hyprland.
- Display resolution, refresh rate, scale, transform, and position controls.
- Night light.

## Required approach

- Degrade gracefully when BlueZ, an audio backend, a display backend, or any
  other optional dependency is unavailable.
- Keep discovery, device operations, and backend calls asynchronous so the QML
  UI thread is never blocked.
- Do not overwrite the entire Hyprland configuration; make only safe, targeted
  changes through suitable existing integration points.
- Preserve Caelestia's codebase, branding, visual style, and existing
  fluid/morphing animation language.
- Build and test all changes before committing.
- Update `INTEGRATION_NOTES.md` with any shared integration or configuration
  requirements.

## Ownership boundaries

- Do not modify the shared config schema.
- If configuration additions are needed, describe them in
  `INTEGRATION_NOTES.md` for the Desktop Integration worker.
- Do not implement launcher, clipboard, process manager, calendar, or
  notification features.
- Do not work outside the scope above, do not modify another worktree, and do
  not merge another worker's branch.
