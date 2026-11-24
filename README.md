# Pinocator (Swift version)

A macOS menu-bar utility: press a hotkey and huge stroke-only circles
converge onto the mouse cursor point, drawn across all screens as one
continuous animation. A Swift port of the design settled with the
Hammerspoon prototype. See [SPEC.md](SPEC.md) for the design details.
Japanese version: [README-ja.md](README-ja.md).

## Build and run (Mac)

Requirements: macOS 13 or later, Xcode or the Command Line Tools
(Swift 5.9+).

```zsh
cd Pinocator
./scripts/make_app.sh     # produces build/Pinocator.app
open build/Pinocator.app  # success = "◎" appears in the menu bar
```

During development, `swift run` also works (still a menu-bar app).

## Usage

- The default hotkey is **Shift+F12**; pressing it shows the animation
- From the ◎ menu: "Show now", "Settings…", "Quit"
- Settings are stored in UserDefaults and take effect from the next
  trigger (hotkey changes apply immediately)
- No permissions required (uses neither Accessibility nor Screen Recording)

## Notes

- On Apple keyboards F12 may double as a volume key. Either set the
  F keys to behave as standard function keys in System Settings →
  Keyboard, or assign a different key in the settings window
- Signed ad hoc only; not notarized. Intended for your own Mac

## Layout

- `Sources/Pinocator/main.swift` — entry point
- `AppDelegate.swift` — menu bar, settings window, hotkey wiring
- `HotkeyManager.swift` — Carbon RegisterEventHotKey
- `OverlayController.swift` — per-screen overlays and mode branching
- `RippleView.swift` — converging-circle drawing and animation
  (including the glass-style look)
- `HintView.swift` — hint-mode badge (arrow + screen name)
- `Settings.swift` — settings store (UserDefaults)
- `SettingsView.swift` / `HotkeyRecorderView.swift` — settings GUI
- `ModernSlider.swift` — custom slider for the settings GUI
  (the thumb is Liquid Glass on macOS 26 and later)
- `Geometry.swift` — platform-independent math (auto radius, ring
  radius/alpha, 8-way arrow). Foundation only, so it can be tested
  on Linux too
- `Tests/GeometryTests/main.swift` — unit tests for Geometry

## Tests

The Geometry unit tests run on both macOS and Linux:

```zsh
swiftc Sources/Pinocator/Geometry.swift Tests/GeometryTests/main.swift -o /tmp/geomtest
/tmp/geomtest
```

## Known limitations / TODO

- The key name shown in the menu's "Show now" item is captured at
  launch (it does not follow hotkey changes; harmless)
- No app icon, no launch-at-login
- Build and behaviour verified on a real Mac (2026-11-24), including
  multi-screen setups with SpaceWalker virtual displays. On the Linux
  development VM, all sources pass syntax checks (swiftc -parse) and
  the 13 Geometry unit tests pass, using Swift 6.4.3
