# Integration Notes

Record contracts or changes that another worker must integrate. Keep this file
current while implementing the task.

## Shared or config changes requested

- Desktop Integration may expose configurable launcher prefixes for indexed
  files and running windows. This worker deliberately did not modify the shared
  schema; the current commands use the existing launcher action prefix as
  `<actionPrefix>file ` and `<actionPrefix>window `.

## Shared interfaces and integration points

- The existing `search.prefix.emojis` value selects the emoji provider.
- The existing `search.prefix.shellCommand` value selects the safe command
  runner. Commands are parsed with `CUtils.splitCommand()` and executed as an
  argv list without a shell.
- Running-window results reuse `services/Hypr.qml`; no duplicate compositor
  service or generic provider interface was added.

## Optional dependencies and graceful-degradation behavior

- Indexed file search invokes `locate` asynchronously with an argv command and
  a result limit. If `locate` (plocate/mlocate) or its database is unavailable,
  the provider returns no results and the rest of the launcher remains usable.
- Emoji copying uses Quickshell's clipboard API and adds no dependency.

## Build and test evidence

- `git diff --check`: passed.
- Launcher safety/integration assertions: passed (direct argv execution,
  bounded asynchronous `locate`, reused Hypr service, clipboard integration,
  and provider state/delegate coverage).
- Rapid file-query replacement is serialized across `Process` shutdown; stale
  output is discarded by comparing the running and requested queries.
- CMake configure/build could not start in the assigned environment because
  `cmake` is not installed or available in `PATH` (`exit 127`).
- `scripts/qml-lint-conventions.py` could not run because the repository's
  existing script references `Violation` before it is defined (`NameError` at
  line 124). The script was not modified because it is outside Launcher scope.
- PySide 6.9.1 `qmllint` and `qmlformat` parsed the changed QML without syntax
  errors. Full type resolution remains unavailable because this environment
  has no Quickshell/Caelestia QML import installation.
- No `quickshell` or Nix executable is available in this environment for an
  alternative runtime/build validation.
