## Limitations

- As the name implies, the Feature is expected to work when the host is running Docker (or the OSS Moby container engine it is built on). It may be possible to get running in other container engines, but it has not been tested with them.
- The host and the container must be running on the same chip architecture. You will not be able to use it with an emulated x86 image with Docker Desktop on an Apple Silicon Mac, for example.
- This approach does not currently enable bind mounting the workspace folder by default, and cannot support folders outside of the workspace folder. Consider whether the [Docker-in-Docker Feature](../docker-in-docker) would better meet your needs given it does not have this limitation.

## Supporting bind mounts from the workspace folder

A common question that comes up is how you can use `bind` mounts from the Docker CLI from within the a dev container using this Feature (e.g. via `-v`). If you cannot use the [Docker-in-Docker Feature](../docker-in-docker), the only way to work around this is to use the **host**'s folder paths instead of the container's paths. There are 2 ways to do this

### 1. Use the `${localWorkspaceFolder}` as environment variable in your code

1. Add the following to `devcontainer.json`:

```json
"remoteEnv": { "LOCAL_WORKSPACE_FOLDER": "${localWorkspaceFolder}" }
```

2. Usage with Docker commands

```bash
docker run -it --rm -v ${LOCAL_WORKSPACE_FOLDER}:/workspace debian bash
```

3. Usage with Docker-compose

```yaml
version: "3.9"

services:
  debian:
    image: debian
    volumes:
      - ${LOCAL_WORKSPACE_FOLDER:-./}:/workspace
```

- The defaults value `./` is added so that the `docker-compose.yaml` file can work when it is run outside of the container

### 2. Change the workspace to `${localWorkspaceFolder}`

- This is useful if we don't want to edit the `docker-compose.yaml` file

1. Add the following to `devcontainer.json`

```json
"workspaceFolder": "${localWorkspaceFolder}",
"workspaceMount": "source=${localWorkspaceFolder},target=${localWorkspaceFolder},type=bind"
```

2. Rebuild the container.
3. When the container first started with this settings, select the Workspace with the absolute path to the working directory inside the container
4. Docker commands with bind mount should work as they did outside of the devcontainer

> **Note:** There is no `${localWorkspaceFolder}` when using the **Clone Repository in Container Volume** command in the VS Code Dev Containers extension ([info](https://github.com/microsoft/vscode-remote-release/issues/6160#issuecomment-1014701007)).


## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

Debian Trixie (13) does not include moby-cli and related system packages, so the feature cannot install with "moby": "true". To use this feature on Trixie, please set "moby": "false" or choose a different base image (for example, Ubuntu 24.04).

Ubuntu 26.04 LTS (Resolute) now has moby-cli packages available, so the feature supports installation with either `"moby": true` or `"moby": false`.

`bash` is required to execute the `install.sh` script.

## Socket access for non-root users

By default, if the host Docker socket's group ID is not used by any group in the container, the Feature changes the GID of the container's `docker` group to match it when the container starts. Processes that were already running at that point (for example the container's own command when `overrideCommand` is `false`) keep their old supplementary groups and get `permission denied` on the socket. Processes started afterwards, such as terminals and `docker exec`, are not affected.

Set `alwaysUseSocketProxy` to `true` to avoid this. The Feature then always forwards the host socket to `/var/run/docker.sock` with `socat`, and that socket is owned by the non-root user, so no group membership is needed. The Feature already falls back to this proxy when the socket is owned by `root` or its GID is already taken inside the container. The option has no effect when the remote user is `root`, because `root` can use the socket directly.

```json
"features": {
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {
        "alwaysUseSocketProxy": true
    }
}
```

> **Note:** The proxy can drop delayed output ([#483](https://github.com/devcontainers/features/issues/483)). The Docker CLI closes its write side right after sending a request, and `socat` then gives the daemon only 0.5 seconds to send anything more before it closes the connection. Output that arrives later is lost. This affects `docker run` and `docker exec` with or without `--interactive`, for example `docker run --rm ubuntu sh -c 'sleep 5; date'` prints nothing. The same applies when the Feature falls back to the proxy on its own, so consider it before enabling the option.
