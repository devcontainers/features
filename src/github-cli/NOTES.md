## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.

## Extensions

If you set the `extensions` option, the feature will run `gh extension install` for each entry (comma-separated). Extensions are installed for the most appropriate non-root user (based on `USERNAME` / `_REMOTE_USER`), with a fallback to `root`.
