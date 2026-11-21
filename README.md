# keywarp

A tiny, headless macOS utility that summons apps with global keyboard shortcuts. Press a shortcut and its app comes to the front, exactly as if you'd clicked its Dock icon; if the app isn't running, it launches.

- No Dock icon, no menu bar item, no windows, no overlays.
- No Accessibility or Input Monitoring permission: shortcuts use `RegisterEventHotKey`.
- No polling. Idle until a shortcut is pressed or the config file changes.
- Swift and Apple frameworks only. No dependencies.

Requires macOS 14+ on Apple Silicon, with Homebrew and Xcode Command Line Tools 16+ (Swift 6).

## Install

```sh
brew tap hoelter/keywarp https://github.com/hoelter/keywarp
brew install keywarp
brew services start keywarp
```

`brew services` starts keywarp at login and restarts it if it exits.

Update with `brew upgrade keywarp && brew services restart keywarp`.

## Configure

Create `~/.config/keywarp/config.json`:

```json
{
  "bindings": [
    { "shortcut": "cmd+1", "app": "com.apple.Safari" },
    { "shortcut": "cmd+2", "app": "com.mitchellh.ghostty" },
    { "shortcut": "cmd+3", "app": "com.spotify.client" }
  ]
}
```

keywarp reloads the file as soon as you save it. Run `keywarp check` to validate it.

- **`app`** is the app's bundle identifier. Find one with `osascript -e 'id of app "Safari"'`.
- **`shortcut`** is modifiers plus one key, joined by `+`, in any order and any case.
  - Modifiers: `cmd`, `ctrl`, `opt`, `shift`. At least one of `cmd`, `ctrl` or `opt` is required.
  - Keys: `a`–`z`, `0`–`9`, `f1`–`f20`, `` ` `` `-` `=` `[` `]` `\` `;` `'` `,` `.` `/`, `space`, `return`, `tab`, `escape`, `delete`, `forwarddelete`, `home`, `end`, `pageup`, `pagedown`, `left`, `right`, `up`, `down`.
  - Keys are physical positions on a US keyboard layout.

A shortcut belongs to keywarp in every app, so `cmd+1` no longer switches tabs anywhere.

If the file has any problem, including an unknown key, keywarp rejects all of it and keeps the shortcuts it already has. A binding whose app isn't installed on this Mac is logged and otherwise ignored, so one config works across machines.

## Logs

```sh
log stream --predicate 'subsystem == "io.github.hoelter.keywarp"'
```

## Uninstall

```sh
brew services stop keywarp
brew uninstall keywarp
brew untap hoelter/keywarp
```

## Develop

```sh
make test     # swift test
make bundle   # build/Keywarp.app
make release VERSION=X.Y.Z   # tag, push, and point Formula/keywarp.rb at the new tarball
```
