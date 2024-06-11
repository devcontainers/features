
# PowerShell (powershell)

Installs PowerShell along with needed dependencies. Useful for base Dockerfiles that often are missing required install dependencies like gpg.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/powershell:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a version of PowerShell. | string | latest |
| modules | Optional comma separated list of PowerShell modules to install. If you need to install a specific version of a module, use '==' to specify the version (e.g. 'az.resources==2.5.0') | string | - |
| powershellProfileURL | Optional (publicly accessible) URL to download PowerShell profile. | string | - |

## Customizations

### VS Code Extensions

- `ms-vscode.powershell`



## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/powershell/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
