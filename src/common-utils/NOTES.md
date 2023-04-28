## OS Support

This Feature should work on recent versions of Debian/Ubuntu, RedHat Enterprise Linux, Fedora, RockyLinux, and Alpine Linux.

## Base Images

This feature is used in many of the devcontainer [base images](https://github.com/devcontainers/images), as a result
those base images have already allocated UID & GID 1000. Attempting to add this feature on a new configuration utilizing
a devcontainer base image may result in an error when building if adding a new user and assiging UID or GID to 1000. 

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
