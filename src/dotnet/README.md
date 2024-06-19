
# Dotnet CLI (dotnet)

This Feature installs the latest .NET SDK, which includes the .NET CLI and the shared runtime. Options are provided to choose a different version or additional versions.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/dotnet:2": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a .NET SDK version. Use 'latest' for the latest version, 'lts' for the latest LTS version, 'X.Y' or 'X.Y.Z' for a specific version. | string | latest |
| additionalVersions | Enter additional .NET SDK versions, separated by commas. Use 'latest' for the latest version, 'lts' for the latest LTS version, 'X.Y' or 'X.Y.Z' for a specific version. | string | - |
| dotnetRuntimeVersions | Enter additional .NET runtime versions, separated by commas. Use 'latest' for the latest version, 'lts' for the latest LTS version, 'X.Y' or 'X.Y.Z' for a specific version. | string | - |
| aspNetCoreRuntimeVersions | Enter additional ASP.NET Core runtime versions, separated by commas. Use 'latest' for the latest version, 'lts' for the latest LTS version, 'X.Y' or 'X.Y.Z' for a specific version. | string | - |
| workloads | Enter additional .NET SDK workloads, separated by commas. Use 'dotnet workload search' to learn what workloads are available to install. | string | - |

## Customizations

### VS Code Extensions

- `ms-dotnettools.csharp`

## Configuration examples

Installing only the latest .NET SDK version (the default).

``` jsonc
"features": {
    "ghcr.io/devcontainers/features/dotnet:2": "latest" // or "" or {}
}
```

Installing an additional SDK version. Multiple versions can be specified as comma-separated values.

``` json
"features": {
    "ghcr.io/devcontainers/features/dotnet:2": {
        "additionalVersions": "lts"
    }
}
```

Installing specific SDK versions.

``` json
"features": {
    "ghcr.io/devcontainers/features/dotnet:2": {
        "version": "6.0",
        "additionalVersions": "7.0, 8.0"
    }
}
```

Installing a specific SDK feature band.

``` json
"features": {
    "ghcr.io/devcontainers/features/dotnet:2": {
        "version": "6.0.4xx",
    }
}
```

Installing a specific SDK patch version.

``` json
"features": {
    "ghcr.io/devcontainers/features/dotnet:2": {
        "version": "6.0.412",
    }
}
```

Installing only the .NET Runtime or the ASP.NET Core Runtime. (The SDK includes all runtimes so this configuration is only useful if you need to run .NET apps without building them from source.)

``` json
"features": {
    "ghcr.io/devcontainers/features/dotnet:2": {
        "version": "none",
        "dotnetRuntimeVersions": "latest, lts",
        "aspnetCoreRuntimeVersions": "latest, lts",
    }
}
```

Installing .NET workloads. Multiple workloads can be specified as comma-separated values.

``` json
"features": {
    "ghcr.io/devcontainers/features/dotnet:2": {
      "workloads": "aspire, wasm-tools"
    }
}
```

## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/dotnet/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
