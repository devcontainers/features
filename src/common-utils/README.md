
# Common Debian Utilities (common-utils)

Installs a set of common command line utilities, Oh My Zsh!, and sets up a non-root user.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/common-utils:1": {
        "version": "latest"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| installZsh | Install ZSH? | boolean | true |
| installOhMyZsh | Install Oh My Zsh!? | boolean | true |
| upgradePackages | Upgrade OS packages? | boolean | true |
| username | Enter name of non-root user to configure or none to skip | string | automatic |
| uid | Enter uid for non-root user | string | automatic |
| gid | Enter gid for non-root user | string | automatic |
| nonFreePackages | Add packages from non-free Debian repository? | boolean | false |

## Speeding up the command prompt in large repositories

This script provides a custom command prompt that includes information about the git repository for the current folder. However, with certain large repositories, this can result in a slow command prompt since the required git status command can be slow. To resolve this, you can update a git setting to remove the git portion of the command prompt.

To disable the prompt for the current folder's repository, enter the following in a terminal or add it to your `postCreateCommand` or dotfiles:

```bash
git config codespaces-theme.hide-status 1
```

This setting will survive a rebuild since it is applied to the repository rather than the container.



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/common-utils/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
