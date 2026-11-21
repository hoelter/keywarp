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
Bringing a Target to the front exactly as a Dock-icon click would, launching it first if it isn't running. Summoning a Target that is already frontmost does nothing.
_Avoid_: Activate, toggle, switch, focus
