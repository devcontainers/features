
# Nix Package Manager (nix)

Installs the Nix package manager and optionally a set of packages.

## Example Usage

```json
"features": {
    "ghcr.io/braechnov/features/nix:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of Nix to install. | string | latest |
| multiUser | Perform a multi-user install (instead of single user) | boolean | true |
| packages | Optional comma separated list of Nix packages to install in profile. | string | - |
| flakeUri | Optional URI to a Nix Flake to install in profile. | string | - |
| extraNixConfig | Optional comma separated list of extra lines to add to /etc/nix/nix.conf. | string | - |

## OS Support

This Feature should work on recent versions of Debian/Ubuntu, RedHat Enterprise Linux, Fedora, RockyLinux, and Alpine Linux.

## Location of Flakes

Currently `flakeUri` works best with a remote URI (e.g., `github:nixos/nixpkgs/nixpkgs-unstable#hello`) as local files need to be in the image.

> Proposed support for lifecycle hooks in Features ([#60](https://github.com/devcontainers/spec/issues/60)) would allow for expressions files or Flakes to exist in the source tree to be automatically installed on initial container startup, but today you will have to manually add the appropriate install command to `postCreateCommand` to your `devcontainer.json` instead.

## Multi-user vs. single-user installs

This Dev Container Feature supports two installation models for Nix: multi-user and single user. Multi-user is the default, but each has pros and cons.

| Installation Model | Pros | Cons |
| --- | --- | --- |
| *Multi-User* | Nix can be used with any user including root.<br /><br />Also still works if the UID or GID of any user is updated. | Only works with Nix 2.11 and up due to a Nix installer limitation.<br /><br />Container must run either: run as root (but `remoteUser` in devcontainer.json can be non-root), or includes `sudo` with the `remoteUser` being configured to use it. <br /><br />Note that automated start of the `nix-daemon` requires passwordless `sudo` if the container itself (e.g., `containerUser`) is not running as root. Manual startup using `sudo` can require a password, however (more next). |
| *Single-User* | Does not require the container to run as root or `sudo` to be included in the image. | Only works with the user specified in the `remoteUser` property or an auto-detected user. If this user's UID/GID is updated, that user will no longer be able to work with Nix. This is primarily a consideration when running on Linux where the UID/GID is sync'd to the local user. |

### Manually starting the Nix daemon

If you have `sudo` in your base image, but have a password set so automatic startup is not possible, you can manually start the Nix daemon by running the following command in a terminal:

```bash
sudo /usr/local/share/nix-entrypoint.sh
```

This same command can be used to restart the daemon if it has stopped for some reason. Logs are available at `/tmp/nix-daemon.log`.


## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/braechnov/features/blob/main/src/nix/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
