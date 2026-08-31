## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.

## Extensions

If you set the `extensions` option, the feature will install each comma-separated entry. Extensions are installed for the most appropriate non-root user (based on `USERNAME` / `_REMOTE_USER`), with a fallback to `root`.

Private extensions can be installed when `GH_TOKEN` or `GITHUB_TOKEN` is available during feature installation. The token is forwarded to the selected non-root user and used through the GitHub CLI Git credential helper.
