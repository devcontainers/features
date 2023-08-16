
# Azure CLI (azure-cli)

Installs the Azure CLI along with needed dependencies. Useful for base Dockerfiles that often are missing required install dependencies like gpg.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/azure-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter an Azure CLI version. (Available versions may vary by Linux distribution.) | string | latest |
| extensions | Optional comma separated list of Azure CLI extensions to install in profile. | string | - |
| installBicep | Optionally install Azure Bicep | boolean | false |
| installUsingPython | Install Azure CLI using Python instead of pipx | boolean | false |

## Customizations

### VS Code Extensions

- `ms-vscode.azurecli`



## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/azure-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
