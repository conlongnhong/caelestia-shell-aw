# Integration Notes

Record contracts or changes that another worker must integrate. Keep this file
current while implementing the task.

## Shared or config changes requested

- No shared schema change is required.
- To make night light available after login, Desktop Integration should start
  `hyprsunset` once (for example with Hyprland `exec-once = hyprsunset` or its
  systemd user service). The Control Center intentionally does not persist or
  overwrite the user's Hyprland configuration.

## Shared interfaces and integration points

- New `display` Nexus page id is registered locally. It uses
  `services/DisplayManager.qml` and applies only the selected output through
  `hyprctl keyword monitor ...`.
- Audio profile selection augments the existing PipeWire `Audio` service via
  `services/AudioProfiles.qml`; it does not replace volume, mute, routing, or
  stream handling already owned by `Audio.qml`.
- Bluetooth continues to use Quickshell's BlueZ-backed singleton and existing
  Caelestia pages; no duplicate Bluetooth daemon or service was introduced.

## Optional dependencies and graceful-degradation behavior

- Missing BlueZ/default adapter leaves Bluetooth controls disabled and empty.
- Missing PipeWire leaves existing sink/source lists empty. Missing `pactl`
  shows a profile-backend placeholder while volume/routing remains usable.
- Missing Hyprland/`hyprctl` shows an unavailable display backend and prevents
  apply actions.
- Missing or inactive `hyprsunset` disables night-light controls. Starting
  `hyprsunset` and reopening/reloading the shell enables them.

## Build and test evidence

- `git diff --check`: passed.
- QML convention check (run with postponed annotation evaluation because the
  repository script currently references `Violation` before declaring it): no
  new violations; six pre-existing violations remain in `ResourceUsage.qml`,
  `WeatherEntry.qml`, `Lock.qml`, and `shell.qml`.
- Python helper compilation and config-audit CLI smoke check: passed.
- CMake configure was attempted with `cmake -S . -B build
  -DENABLE_MODULES='extras;plugin;shell' -DBUILD_TESTING=ON`, but this worker
  image has neither CMake nor the Qt 6 development toolchain installed. No
  build directory or generated artifact was produced.
