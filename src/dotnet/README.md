
# Dotnet CLI (dotnet)



## Example Usage

```json
"features": [
    {
        "id": "devcontainers/features/dotnet@latest",
        "options": {
            "version": "latest"
        }
    }
]
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a dotnet CLI version. (Available versions may vary by Linux distribution.) | string | latest |
| runtime_only | Install just the dotnet runtime if true, and sdk if false. | boolean | - |
| override_default_version | If true, overrides existing version (if any) of dotnet on the PATH | boolean | true |
| install_using_apt | If true, it installs using apt instead of the release URL | boolean | true |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](./devcontainer-feature.json)._
