# Andrew Arcade — Driver

Andrew Arcade is an open-source game console built on Raspberry Pi 5. The **driver** is the launcher app — it manages and launches games/apps from a central registry. Built with Godot 4.6 (GDScript, Forward Plus renderer, Jolt Physics), rewritten in Godot for native arm64 support.

## Building

Requires `godot` (4.6+) on PATH.

```bash
# Build all export presets to builds/<version>/
./build.sh

# Run in the editor
godot --path godot-project

# Export a single preset
godot --headless --path godot-project --export-release "linux-arm64" output.arm64
godot --headless --path godot-project --export-release "linux-x86_64" output.x86_64
```

The project exports two Linux presets: `linux-arm64` (primary, runs natively on Pi 5) and `linux-x86_64`.

## App Ecosystem Architecture

The driver discovers and launches apps through two pieces:

1. **`applications.json`** — A registry listing repo URLs of all available apps.
2. **`cabinet.json`** — A per-app manifest living at the root of each app's repo, describing how to display and launch it.

Apps are cloned to a fixed local directory (`~/.andrewarcade/apps/`). The driver checks this directory to know what's installed.

### User Actions

- **Install**: Clone the app's repo into `~/.andrewarcade/apps/<repo-name>/`, then read its `cabinet.json`.
- **Update**: `git pull` in the app's local directory.
- **Remove**: Delete the app's directory from `~/.andrewarcade/apps/`.

### Update Detection

The driver uses git to check if an installed app is behind its remote:

1. `git fetch` in the app's local directory.
2. Compare local HEAD against remote HEAD (`git rev-parse HEAD` vs `git rev-parse @{u}`).
3. If they differ, the app has an update available.

No version field is needed — git is the source of truth for freshness.

### Flow

1. The driver reads `applications.json` to get the list of available app repo URLs.
2. It scans `~/.andrewarcade/apps/` to determine which apps are already installed.
3. For installed apps, it reads each app's `cabinet.json` for display info and launch config.
4. For uninstalled apps, it shows them as available for install.
5. The driver periodically fetches remotes to check for updates.
6. When the user selects an installed app, the driver launches it using the command and runtime specified in `cabinet.json`.

## `applications.json` Spec

Maintained in the driver repo (or fetched from a remote URL). A simple list of git repo URLs.

```json
{
  "apps": [
    "https://github.com/AndrewArcade/example-game",
    "https://github.com/AndrewArcade/another-app"
  ]
}
```

The driver derives the app identity from the repo URL (e.g. the repo name) and reads all metadata from `cabinet.json` after cloning.

## `cabinet.json` Spec

Lives at the root of each app's repo. Tells the driver how to display and launch the app.

```json
{
  "display_name": "Example Game",
  "description": "A fun example game for Andrew Arcade.",
  "icon": "icon.png",
  "launch": {
    "command": "./example-game.arm64",
    "arch": "arm64"
  }
}
```

| Field             | Type   | Description                                                        |
|-------------------|--------|--------------------------------------------------------------------|
| `display_name`    | string | Name shown in the launcher UI                                      |
| `description`     | string | Short description shown in the launcher                            |
| `icon`            | string | Path to icon image, relative to app repo root                      |
| `launch.command`  | string | Command to execute to start the app, relative to app repo root     |
| `launch.arch`     | string | Target architecture: `arm64` (native) or `x86_64` (runs via box64) |

When `launch.arch` is `x86_64`, the driver prepends `box64` to the launch command automatically, running the app through x86_64 emulation on the Pi 5.

## License

Open source. See individual app repos for their respective licenses.
