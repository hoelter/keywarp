# Summon through LaunchServices, not NSRunningApplication.activate

keywarp Summons every Target with `NSWorkspace.openApplication`, even when the Target is already running, instead of the obvious `NSRunningApplication.activate()`. Since macOS 14, `activate()` from a background app is only a request the system may silently ignore: Apple's cooperative-activation rules let only the active app yield focus, and keywarp is never active. LaunchServices is what working background launchers (Thor, Karabiner, Hammerspoon's `launchOrFocus`) use, and it also gives Dock-click behaviour for free: it unhides the app, restores a minimized window, and sends the reopen event that makes an app with no windows open one.

## Consequences

- Each Summon pays for a LaunchServices round trip rather than a direct call. It was never measured; in use it feels instant.
- For a running Target, keywarp opens the running copy's bundle URL, so a second installed copy is never launched alongside it.
- A faster `activate()` path with an `openApplication` fallback was considered but needs a probe on real key presses to show `activate()` works from a hotkey handler. It hasn't been run.
