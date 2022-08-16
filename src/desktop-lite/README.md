
# Light-weight Desktop (desktop-lite)

Adds a lightweight Fluxbox based desktop to the container that can be accessed using a VNC viewer or the web. GUI-based commands executed from the built-in VS code terminal will open on the desktop automatically.

## Example Usage

```json
"features": {
        "ghcr.io/devcontainers/features/desktop-lite:1": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Currently Unused! | string | latest |
| noVncVersion | NoVnc Version | string | 1.2.0 |
| password | Enter a password for desktop connections | string | vscode |
| webPort | Enter a port for the VNC web client | string | 6080 |
| vncPort | Enter a port for the desktop VNC server | string | 5901 |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/desktop-lite/devcontainer-feature.json)._
