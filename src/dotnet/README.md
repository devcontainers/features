
# Dotnet CLI (dotnet)

Installs the .NET CLI. Provides option of installing sdk or runtime, and option of versions to install. Uses latest version of .NET sdk as defaults to install.

## Example Usage

```json
"features": {
    "ghcr.io/braechnov/features/dotnet:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a dotnet CLI version. (Available versions may vary by Linux distribution.) | string | latest |
| runtimeOnly | Install just the dotnet runtime if true, and sdk if false. | boolean | false |
| installUsingApt | If true, it installs using apt instead of the release URL | boolean | true |



## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/braechnov/features/blob/main/src/dotnet/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
