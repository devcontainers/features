## Limitations

This docker-in-docker Dev Container Feature is roughly based on the [official docker-in-docker wrapper script](https://github.com/moby/moby/blob/master/hack/dind) that is part of the [Moby project](https://mobyproject.org/). With this in mind:
* As the name implies, the Feature is expected to work when the host is running Docker (or the OSS Moby container engine it is built on). It may be possible to get running in other container engines, but it has not been tested with them.
* The host and the container must be running on the same chip architecture. You will not be able to use it with an emulated x86 image with Docker Desktop on an Apple Silicon Mac, like in this example:
  ```
  FROM --platform=linux/amd64 mcr.microsoft.com/devcontainers/typescript-node:24
  ```
  See [Issue #219](https://github.com/devcontainers/features/issues/219) for more details.


## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

Debian Trixie (13) does not include moby-cli and related system packages, so the feature cannot install with "moby": "true". To use this feature on Trixie, please set "moby": "false" or choose a different base image (for example, Ubuntu 24.04).

Ubuntu 26.04 (Resolute) does not currently have moby packages available, so the feature cannot install with "moby": "true". To use this feature on Resolute, please set "moby": "false". Additionally, the kernel on Ubuntu 26.04 no longer supports legacy iptables NAT tables, so the feature automatically falls back to `iptables-nft` when `iptables-legacy` is not functional.

`bash` is required to execute the `install.sh` script.

## Persisted state

This Feature mounts two named Docker volumes into the dev container so that the daemons have writable, non-overlay storage for their state:

* `dind-var-lib-docker-${devcontainerId}` → `/var/lib/docker`
* `dind-var-lib-containerd-${devcontainerId}` → `/var/lib/containerd`

The `/var/lib/containerd` mount is required when the dev container's root filesystem is itself an overlayfs mount (the default in Kubernetes / containerd-backed hosts, GitHub Codespaces, and Docker with the containerd image store enabled). Without it, the standalone `containerd` started by this Feature would place its overlayfs snapshotter data on an overlay rootfs, causing overlay-on-overlay mounts to fail with `invalid argument`. See [issue #1639](https://github.com/devcontainers/features/issues/1639) for background.

Because both volumes are scoped to `${devcontainerId}`, each dev container gets its own state and rebuilds preserve images and snapshots. Removing the dev container does not automatically remove these volumes; clean them up with `docker volume rm` if you want to reclaim space.
