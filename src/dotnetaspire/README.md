
# .NET Aspire (dotnetaspire)

This Feature installs .NET Aspire and if necessary the .NET (dotnet) that it depends on. Options are provided to choose a different version or additional versions.

## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions that support .NET and have the `apt` package manager installed

`bash` is required to execute the `install.sh` script.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/dotnetaspire:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | .NET Aspire version. Use 'latest' for the latest supported version, '9.0' for the 9.0 version, 'X.Y' or 'X.Y.Z' for a specific version, or 'latest-daily' for the latest unsupported build. | string | latest |

## Customizations

### VS Code Extensions

- `ms-dotnettools.csdevkit`

## Configuration examples

Installing only the latest .NET Aspire version (the default).

``` jsonc
"features": {
    "ghcr.io/devcontainers/features/dotnetaspire:1": "latest" // or "" or {}
}
```

Installing .NET Aspire version 9.0.

``` jsonc
"features": {
    "ghcr.io/devcontainers/features/dotnetaspire:1": "9.0" // or "" or {}
}
```

Installing the latest .NET Aspire unsupported build.

``` jsonc
"features": {
    "ghcr.io/devcontainers/features/dotnetaspire:1": "latest-daily" // or "" or {}
}
```


## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.

