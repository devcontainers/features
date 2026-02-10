
# GitHub CLI (github-cli)

Installs the GitHub CLI. Auto-detects latest version and installs needed dependencies.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/github-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of the GitHub CLI, if not latest. | string | latest |
| installDirectlyFromGitHubRelease | - | boolean | true |
| extensions | Comma-separated list of GitHub CLI extensions to install (e.g. 'dlvhdr/gh-dash,github/gh-copilot'). | string | - |

## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.

## Extensions

If you set the `extensions` option, the feature will run `gh extension install` for each entry (comma-separated). Extensions are installed for the most appropriate non-root user (based on `USERNAME` / `_REMOTE_USER`), with a fallback to `root`.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/github-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
