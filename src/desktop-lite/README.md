
# Light-weight desktop (Fluxbox) (desktop-lite)



## Example Usage

```json
"features": [
    "desktop-lite": {
        "id": "devcontainers/features/#{featureId}@latest",
        "options": {
            "version": "latest"
        }
    }
]
```

## Options

| Options Id | Description | Type | Default Value ||-----|-----|-----|-----|
| version | Currently Unused! | string | latest |
| novnc_version | NoVnc Version | string | 1.2.0 |
| vnc_password | Enter a password for desktop connections | string | vscode |
| novnc_port | Enter a port for the VNC web client | string | 6080 |
| vnc_port | Enter a port for the desktop VNC server | string | 5901 |

---

_Note: This is an auto-generated file. Please do not directly edit._
