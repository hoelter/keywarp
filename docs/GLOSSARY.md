# keywarp

A headless macOS utility that brings applications to the front, or launches them, from global keyboard shortcuts.

## Language

**Shortcut**:
A key combination of one or more modifiers plus a single key, such as ⌘1.
_Avoid_: Hotkey, keybind, key combo

**Target**:
The application a Shortcut points to, identified by its bundle identifier.
_Avoid_: App (when ambiguous), program

**Binding**:
One Shortcut paired with one Target, as declared in the config.
_Avoid_: Mapping, rule, keybinding

**Summon**:
Bringing a Target to the front exactly as a Dock-icon click would, launching it first if it isn't running.
_Avoid_: Activate, toggle, switch, focus

**Dismiss**:
Hiding a Target that is already frontmost; macOS then chooses which app comes forward, usually the previously active one. Pressing a Shortcut Summons its Target, or Dismisses it if it is already frontmost.
_Avoid_: Toggle off, minimize, close
