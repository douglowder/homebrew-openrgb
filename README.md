# douglowder/openrgb

`openrgbd`, the OpenRGB SDK server with no user interface, packaged as a Homebrew
service. It builds the OpenRGB core and the daemon from
[douglowder/OpenRGB](https://github.com/douglowder/OpenRGB); the Qt application is
not part of this formula.

```
brew tap douglowder/openrgb
brew install openrgbd
brew services start openrgbd
```

`brew services start` installs a per-user LaunchAgent that runs
`openrgbd --server` on port 6742 at every login, and restarts it if it fails. A
clean stop exits zero, so `brew services stop` stays stopped.

```
brew services info openrgbd     # running, and under which label
brew services restart openrgbd
brew services stop openrgbd
```

| | |
| --- | --- |
| Binary | `$(brew --prefix)/bin/openrgbd` |
| Agent | `~/Library/LaunchAgents/sh.brew.openrgbd.plist` |
| launchd's stdio | `$(brew --prefix)/var/log/openrgbd.log` |
| OpenRGB's own log | `~/.config/OpenRGB/logs/` |

An agent rather than a system daemon: `openrgbd` keeps its configuration and
profiles under the user's home directory, and reaching USB HID devices on macOS
needs a logged-in user rather than root.

## Building from source

`qmake` is the only thing the build takes from Qt, and Homebrew's `qtbase`
supplies it. `qtbase` will not install alongside a force-linked `qt@5`:

```
brew unlink qt@5
brew install --build-from-source openrgbd
```

`brew install --HEAD openrgbd` builds the tip of the `doug/headless-library`
branch instead of the pinned revision.

## Passing arguments to the daemon

`brew services` has no way to pass them, and it regenerates the plist on every
`start`, so an edited plist does not survive. For a startup profile, use
`scripts/openrgbd-launchd.sh` from the OpenRGB tree against the installed
binary:

```
brew services stop openrgbd
scripts/openrgbd-launchd.sh install --binary "$(brew --prefix)/bin/openrgbd" --profile expo
```

See `Documentation/Daemon.md` in the OpenRGB tree for the daemon itself.
