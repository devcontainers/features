
# GitHub Copilot CLI (copilot-cli)

Installs the GitHub Copilot CLI. Auto-detects latest version and installs needed dependencies.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/copilot-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of the GitHub Copilot CLI, if not latest. | string | latest |



## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/copilot-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._