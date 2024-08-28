
# Node.js (via nvm), yarn and pnpm (node)

Installs Node.js, nvm, yarn, pnpm, and needed dependencies.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/node:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a Node.js version to install | string | lts |
| nodeGypDependencies | Install dependencies to compile native node modules (node-gyp)? | boolean | true |
| nvmInstallPath | The path where NVM will be installed. | string | /usr/local/share/nvm |
| pnpmVersion | Select or enter the PNPM version to install | string | latest |
| nvmVersion | Version of NVM to install. | string | latest |
| installYarnUsingApt | On Debian and Ubuntu systems, you have the option to install Yarn globally via APT. If you choose not to use this option, Yarn will be set up using Corepack instead. This choice is specific to Debian and Ubuntu; for other Linux distributions, Yarn is always installed using Corepack, with a fallback to installation via NPM if an error occurs. | boolean | true |

## Customizations

### VS Code Extensions

- `dbaeumer.vscode-eslint`

## Using nvm from postCreateCommand or another lifecycle command

Certain operations like `postCreateCommand` run non-interactive, non-login shells. Unfortunately, `nvm` is really particular that it needs to be "sourced" before it is used, which can only happen automatically with interactive and/or login shells. Fortunately, this is easy to work around:

Just can source the `nvm` startup script before using it:

```json
"postCreateCommand": ". ${NVM_DIR}/nvm.sh && nvm install --lts"
```

Note that typically the default shell in these cases is `sh` not `bash`, so use `. ${NVM_DIR}/nvm.sh` instead of `source ${NVM_DIR}/nvm.sh`.

Alternatively, you can start up an interactive shell which will in turn source `nvm`:

```json
"postCreateCommand": "bash -i -c 'nvm install --lts'"
```



## OS Support

Debian/Ubuntu, RedHat Enterprise Linux, Fedora, Alma, and Rocky Linux distributions with the `apt`, `yum`, `dnf`, or `microdnf` package manager installed.

**Note**:  RedHat 7 Family (RedHat, CentOS, etc.) must use Node versions less than 18 due to its system libraries and long-term support (LTS) policies.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/node/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
