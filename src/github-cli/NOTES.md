## OS Support

This Feature supports Debian/Ubuntu-based distributions using the `apt` package manager, and Alpine Linux using `apk`.

The base image is identified from `/etc/os-release`, using `ID` first and then each entry of `ID_LIKE`, so derivatives are covered by the
distribution they declare themselves to be like — Kali, Raspbian, Pop!\_OS and Zorin all resolve to the Debian installer. On a distribution
that is not yet supported, the Feature stops with a message naming the base image rather than failing part-way through an install.

> [!NOTE]
> `bash` is required to execute the `install.sh` script on Debian-based distros. Debian-based images *generally* provide `bash` by default,
> but if you're using one that does not please note that you'll need to ensure it's installed *before* the `github-cli` feature installer
> runs.
>
> On Alpine-based distros, `bash` is only needed when `extensions` option is set and is installed automatically in that case. Please note
> that this does mean that `bash` will be present in the container if you use the `extensions` option on Alpine images.

### Choosing an installation source

`installDirectlyFromGitHubRelease` selects where the GitHub CLI is installed from:

|               | `true` (default)                                                   | `false`                                                           |
|---------------|--------------------------------------------------------------------|-------------------------------------------------------------------|
| Debian/Ubuntu | the `.deb` published with each GitHub release                      | GitHub's own apt repository at `cli.github.com`                   |
| Alpine        | the statically linked `.tar.gz` published with each GitHub release | the `github-cli` package in Alpine's `community` repository [ref] |

[ref]: https://github.com/cli/cli/blob/trunk/docs/install_linux.md#alpine-linux

Alpine's `community` repository carries a single version of `github-cli`, so a specific `version` cannot be honored when
`installDirectlyFromGitHubRelease` is `false`; it is ignored with a warning. Leave the option at its default to pin a version on Alpine.

## Extensions

If you set the `extensions` option, the feature will install each comma-separated entry. Extensions are installed for the most appropriate
non-root user (based on `USERNAME` / `_REMOTE_USER`), with a fallback to `root`.

Private extensions can be installed when `GH_TOKEN` or `GITHUB_TOKEN` is available during feature installation. The token is forwarded to
the selected non-root user and used through the GitHub CLI Git credential helper.
