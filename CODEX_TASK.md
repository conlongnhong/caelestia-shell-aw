# System Tools Worker Task

## Objective

Extend Caelestia's existing dashboard and services with:

- Clipboard history for both text and images.
- Image thumbnails and previews.
- Clipboard search, pin, delete, clear, and private-mode controls.
- A process manager.
- CPU, RAM, load-average, temperature, and GPU metrics.
- Process termination that sends `SIGTERM` first and requires confirmation
  before using `SIGKILL`.

## Required approach

- Extend the dashboard and services that already exist; do not create duplicate
  services.
- Do not require the shell to run as root.
- Keep collection and process operations asynchronous so the QML UI thread is
  never blocked.
- Make optional tools and metrics backends degrade gracefully when unavailable.
- Preserve Caelestia's codebase, branding, visual style, and existing
  fluid/morphing animation language.
- Build and test all changes before committing.
- Update `INTEGRATION_NOTES.md` with any shared integration or configuration
  requirements.

## Ownership boundaries

- Do not modify the shared config schema.
- If configuration additions are needed, describe them in
  `INTEGRATION_NOTES.md` for the Desktop Integration worker.
- Do not implement launcher, Bluetooth, display, calendar, or idle-policy
  features.
- Do not work outside the scope above, do not modify another worktree, and do
  not merge another worker's branch.
