
# SSH server (sshd)

Adds a SSH server into a container so that you can use an external terminal, sftp, or SSHFS to interact with it.

## Example Usage

```json
"features": {
    "ghcr.io/braechnov/features/sshd:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Currently unused. | string | latest |

## Usage

While the some services automates SSH setup (e.g., when using the GitHub CLI for GitHub Codespaces), this may not be the case for other tools and services. Follow these directions to connect to the dev container from these other tools:

1. Connect to your dev container using a desktop tool or CLI that supports the dev container spec (e.g., VS Code client).

2. The first time you've started the container, you will want to set a password for your user. If running as a user other than root, and you have `sudo` installed:

    ```bash
    sudo passwd $(whoami)
    ```

    Or if you are running as root:

    ```bash
    passwd
    ```

3. Forward the SSH port (`2222` by default) to your local machine using either the `forwardPorts` property in `devcontainer.json` or the user interface in your tool (e.g., you can press <kbd>F1</kbd> or <kbd>Ctrl/Cmd</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> and select **Ports: Focus on Ports View** in VS Code to bring it into focus).

4. Use a **local terminal** (or other tool) to connect to it using the command and password from step 2. e.g.

    ```bash
    ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null vscode@localhost
    ```

    ...where `vscode` above is the user you are running as in the container and `2222` after `-p` is the **local address port** from step 2.

    The “-o” arguments are optional, but will prevent you from getting warnings or errors about known hosts when you do this from multiple containers/codespaces.

5. Next time you connect to your container, just repeat steps 3 and 4 and use the same password you set in step 2.

### Using SSHFS

[SSHFS](https://en.wikipedia.org/wiki/SSHFS) allows you to mount a remote filesystem to your local machine with nothing but a SSH connection. Here's how to use it with a dev container.

1. Follow the steps in the previous section to ensure you can connect to the dev container using the normal `ssh` client.

2. Install a SSHFS client.

    - **Windows:** Install [WinFsp](https://github.com/billziss-gh/winfsp/releases) and [SSHFS-Win](https://github.com/billziss-gh/sshfs-win/releases).
    - **macOS**: Use [Homebrew](https://brew.sh/) to install: `brew install macfuse gromgit/fuse/sshfs-mac`
    - **Linux:** Use your native package manager to install your distribution's copy of the sshfs package. e.g. `sudo apt-get update && sudo apt-get install sshfs`

3. Mount the remote filesystem.

    - **macOS / Linux:** Use the `sshfs` command to mount the remote filesystem. The arguments are similar to the normal `ssh` command but with a few additions. For example: 

        ```
        mkdir -p ~/sshfs/devcontainer
        sshfs "vscode@localhost:/workspaces" "$HOME/sshfs/devcontainer" -p 2222 -o follow_symlinks -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -C
        ```
        ...where `vscode` above is the user you are running as in the container (e.g. `codespace`, `vscode`, `node`, or `root`) and `2222` after the `-p` is the same local port you used in the `ssh` command in step 1.

    - **Windows:** Press Window+R and enter the following in the "Open" field in the Run dialog: 
    
        ```
        \\sshfs.r\vscode@localhost!2222\workspaces
        ```
        ...where `vscode` above is the user you are running as in the container and `2222` after the `!` is the same local port you used in the `ssh` command in the previous section.

4. Your dev container's filesystem should now be available in the `~/sshfs/devcontainer` folder on macOS or Linux or in a new explorer window on Windows.


## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/braechnov/features/blob/main/src/sshd/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
