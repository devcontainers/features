## Supporting bind mounts from the workspace folder

A common question that comes up is how you can use `bind` mounts from the Docker CLI from within the a dev container using this Feature (e.g. via `-v`). The trick is that, since you're actually using the Docker engine sitting outside of the container, the filesystem paths will be different than those in the container. You need to use the **host**'s paths instead.

> **Note:** The docker-from-docker approach does not currently enable bind mounting locations outside of the workspace folder.

### GitHub Codespaces

In GitHub Codespaces, the workspace folder should work with bind mounts by default, so no further action is required.

### Remote - Containers

A simple way to do this is to put `${localWorkspaceFolder}` in an environment variable that you then use when doing bind mounts inside the container.

Add the following to `devcontainer.json`:

```json
"remoteEnv": { "LOCAL_WORKSPACE_FOLDER": "${localWorkspaceFolder}" }
```

Then reference the env var when running Docker commands from the terminal inside the container.

```bash
docker run -it --rm -v ${LOCAL_WORKSPACE_FOLDER}:/workspace debian bash
```

> **Note:** There is no `${localWorkspaceFolder}` when using the **Clone Repository in Container Volume** command ([info](https://github.com/microsoft/vscode-remote-release/issues/6160#issuecomment-1014701007)).