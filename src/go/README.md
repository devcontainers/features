
# Go (go)

Installs Go and common Go utilities. Auto-detects latest version and installs needed dependencies.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/go:1": {
        "version": "latest"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a Go version to install | string | latest |
| golangciLintVersion | Version of golangci-lint to install | string | latest |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/go/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
