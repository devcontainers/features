
# Ruby (via ruby-build) (ruby)

Installs Ruby using ruby-build, with optional rbenv or rvm for version management.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/ruby:2": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a Ruby version to install | string | latest |
| versionManager | Version manager to install alongside Ruby: 'rbenv', 'rvm', or 'none' (ruby-build only) | string | none |

## Customizations

### VS Code Extensions

- `shopify.ruby-lsp`



## OS Support

This Feature supports Linux images that ship one of the following package managers: `apt`, `dnf`/`yum`, `apk`, `zypper`, or `pacman`. The script detects the available package manager and installs the build dependencies that ruby-build needs.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/ruby/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
