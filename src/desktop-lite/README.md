
# Light-weight Desktop (desktop-lite)

Adds a lightweight Fluxbox based desktop to the container that can be accessed using a VNC viewer or the web. GUI-based commands executed from the built-in VS code terminal will open on the desktop automatically.

## Example Usage

```json
"features": {
        "devcontainers/features/desktop-lite@latest": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Currently Unused! | string | latest |
| novnc_version | NoVnc Version | string | 1.2.0 |
| vnc_password | Enter a password for desktop connections | string | vscode |
| novnc_port | Enter a port for the VNC web client | string | 6080 |
| vnc_port | Enter a port for the desktop VNC server | string | 5901 |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](./devcontainer-feature.json)._
