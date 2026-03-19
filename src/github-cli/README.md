# GitHub CLI (github-cli)

Installs the GitHub CLI. Auto-detects latest version and installs needed dependencies.

## Example Usage

### Basic usage

```json
"features": {
    "ghcr.io/devcontainers/features/github-cli:1": {}
}
```

### Authenticate to GitHub

On the first interactive shell after the dev container starts, if you are not already authenticated, the feature tries `gh auth login --with-token` if `GH_TOKEN` or `GITHUB_TOKEN` is available. If those environment variables are not set, it falls back to starting `gh auth login` in an interactive shell.

**Option 1: interactive authentication on setup**

```json
{
    "features": {
        "ghcr.io/devcontainers/features/github-cli:1": {
            "authOnSetup": true
        }
    }
}
```

**Option 2: pass an authentication token from the host**

If you already authenticate on the host with GitHub CLI, export a token before opening the dev container:

```bash
export GITHUB_TOKEN="$(gh auth token)"
```

Then the `remoteEnv` example above will pass that token into the container's post-start auth flow.

```json
{
    "features": {
        "ghcr.io/devcontainers/features/github-cli:1": {
            "authOnSetup": true
        }
    },    
    "remoteEnv": {
        "GITHUB_TOKEN": "${localEnv:GITHUB_TOKEN}"
    }
}
```

### Install GitHub CLI extensions

```json
{
    "features": {
        "ghcr.io/devcontainers/features/github-cli:1": {
            "extensions": "dlvhdr/gh-dash,github/gh-copilot"
        }
    }
}
```

When `extensions` are configured together with `authOnSetup`, extension installation is deferred to the same post-start auth flow so that runtime tokens can be used for authenticated installs. The feature prefers `gh extension install` for each entry when `gh auth status` indicates an authenticated session. If GitHub CLI is not authenticated, or if the native install path fails, the feature falls back to cloning the extension repository into the GitHub CLI extensions directory.

If `extensions` are configured, at least one of `authOnSetup` or `installExtensionsFromGit` must be `true`. The unsupported combination `authOnSetup=false` and `installExtensionsFromGit=false` fails fast during feature setup.

If you want to skip `gh extension install` entirely, set `installExtensionsFromGit` to `true`. In that mode, extensions are installed during feature setup even if `authOnSetup` is also enabled.

```json
{
    "features": {
        "ghcr.io/devcontainers/features/github-cli:1": {
            "extensions": "dlvhdr/gh-dash,github/gh-copilot",
            "installExtensionsFromGit": true
        }
    }
}
```

## Options

| Options Id                       | Description                                                                                                      | Type    | Default Value |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------- | ------- | ------------- |
| version                          | Select version of the GitHub CLI, if not latest.                                                                 | string  | latest        |
| installDirectlyFromGitHubRelease | -                                                                                                                | boolean | true          |
| authOnSetup                      | Automatically authenticate with `gh auth login --with-token` when `GH_TOKEN` or `GITHUB_TOKEN` is available, otherwise start `gh auth login` on the first interactive shell if you are not already authenticated. If `extensions` are configured, this must be true unless `installExtensionsFromGit` is true. | boolean | false         |
| extensions                       | Comma-separated list of GitHub CLI extensions to install (e.g. 'dlvhdr/gh-dash,github/gh-copilot'). Requires either `authOnSetup` or `installExtensionsFromGit` to be true. | string  |               |
| installExtensionsFromGit         | Install `extensions` by cloning their repositories directly instead of using `gh extension install`. Set this to true when `authOnSetup` is false and `extensions` are configured. When `authOnSetup` is enabled, git-based installs happen during feature setup instead of waiting for login. | boolean | false         |

## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/github-cli/devcontainer-feature.json). Add additional notes to a `NOTES.md`._
