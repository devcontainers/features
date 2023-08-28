## Configuration examples

Installing only the latest .NET SDK version (the default).

``` json
{
"features": {
    "ghcr.io/devcontainers/features/dotnet:2": "latest" // or "" or {}
}
```

Installing an additional SDK version. Multiple versions can be specified as comma-separated values.

``` json
{
"features": {
    "ghcr.io/devcontainers/features/dotnet:2": {
        "additionalVersions": "lts"
    }
}
```

Installing specific SDK versions.

``` json
{
"features": {
    "ghcr.io/devcontainers/features/dotnet:2": {
        "version": "6.0",
        "additionalVersions": "7.0, 8.0"
    }
}
```

Installing a specific SDK feature band.

``` json
{
"features": {
    "ghcr.io/devcontainers/features/dotnet:2": {
        "version": "6.0.4xx",
    }
}
```

Installing a specific SDK patch version.

``` json
{
"features": {
    "ghcr.io/devcontainers/features/dotnet:2": {
        "version": "6.0.412",
    }
}
```


## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.
