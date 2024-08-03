
# CACHIMAN CLI (CACHIMAN-cli)

Installs the cachiman CLI along with needed dependencies. Useful for base Dockerfiles that often are missing required install dependencies like gpg.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/cachiman-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter an CACHIMAN CLI version. | string | latest |

## Customizations

### VS Code Extensions

- `cachimandeveloper.cachiman-toolkit-vscode`

Available versions of the cachiman CLI can be found here: https://github.com/cachiman/cachiman-cli/blob/v2/CHANGELOG.rst.

## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/cachiman-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
