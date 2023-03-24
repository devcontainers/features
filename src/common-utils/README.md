
# Common Utilities (common-utils)

Installs a set of common command line utilities, Oh My Zsh!, and sets up a non-root user.

## Example Usage

```json
"features": {
    "ghcr.io/braechnov/features/common-utils:2": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| installZsh | Install ZSH? | boolean | true |
| configureZshAsDefaultShell | Change default shell to ZSH? | boolean | false |
| installOhMyZsh | Install Oh My Zsh!? | boolean | true |
| upgradePackages | Upgrade OS packages? | boolean | true |
| username | Enter name of a non-root user to configure or none to skip | string | automatic |
| userUid | Enter UID for non-root user | string | automatic |
| userGid | Enter GID for non-root user | string | automatic |
| nonFreePackages | Add packages from non-free Debian repository? (Debian only) | boolean | false |

## OS Support

This Feature should work on recent versions of Debian/Ubuntu, RedHat Enterprise Linux, Fedora, RockyLinux, and Alpine Linux.

## Customizing the command prompt

By default, this script provides a custom command prompt that includes information about the git repository for the current folder. However, with certain large repositories, this can result in a slow command prompt due to the performance of needed git operations.

For performance reasons, a "dirty" indicator that tells you whether or not there are uncommitted changes is disabled by default. You can opt to turn this on for smaller repositories by entering the following in a terminal or adding it to your `postCreateCommand`:

```bash
git config devcontainers-theme.show-dirty 1
```

To completely disable the git portion of the prompt for the current folder's repository, you can use this configuration setting instead:

```bash
git config devcontainers-theme.hide-status 1
```

For `zsh`, the default theme is a [standard Oh My Zsh! theme](https://ohmyz.sh/). You may pick a different one by modifying the `ZSH_THEME` variable in `~/.zshrc`.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/braechnov/features/blob/main/src/common-utils/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
