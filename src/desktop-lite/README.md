
# Light-weight desktop (Fluxbox) (desktop-lite)



## Example Usage

```json
"features": [
    {
        "id": "devcontainers/features/desktop-lite@latest",
        "options": {
            "version": "latest"
        }
    }
]
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
