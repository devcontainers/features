
# Git Large File Support (LFS) (git-lfs)

Installs Git Large File Support (Git LFS) along with needed dependencies. Useful for base Dockerfiles that often are missing required install dependencies like git and curl.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/git-lfs:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of Git LFS to install | string | latest |
| autoPull | Automatically pull LFS files when creating the container.  When false, running 'git lfs pull' in the container will have the same effect. | boolean | true |
| installDirectlyFromGitHubRelease | Installs 'git-lfs' from GitHub releases instead of package manager feeds | boolean | false |



## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/git-lfs/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
