
# PowerShell (powershell)

Installs PowerShell along with needed dependencies. Useful for base Dockerfiles that often are missing required install dependencies like gpg.

## Example Usage

```json
"features": {
    "ghcr.io/braechnov/features/powershell:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a version of PowerShell. | string | latest |
| modules | Optional comma separated list of PowerShell modules to install. | string | - |



## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/braechnov/features/blob/main/src/powershell/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
