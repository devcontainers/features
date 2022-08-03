
# Git Large File Support (LFS) (git-lfs)

Installs Git Large File Support (Git LFS) along with needed dependencies. Useful for base Dockerfiles that often are missing required install dependencies like git and curl.

## Example Usage

```json
"features": {
        "ghcr.io/devcontainers/features/git-lfs:1": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of Git LFS to install | string | latest |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](./devcontainer-feature.json)._
