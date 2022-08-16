## Speeding up the command prompt in large repositories

This script provides a custom command prompt that includes information about the git repository for the current folder. However, with certain large repositories, this can result in a slow command prompt since the required git status command can be slow. To resolve this, you can update a git setting to remove the git portion of the command prompt.

To disable the prompt for the current folder's repository, enter the following in a terminal or add it to your `postCreateCommand` or dotfiles:

```bash
git config codespaces-theme.hide-status 1
```

This setting will survive a rebuild since it is applied to the repository rather than the container.

