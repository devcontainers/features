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

## Pre-bundled items

> [!NOTE]
> Beyond the core install, this feature also sets up a few items by default for convenience — recommended VS Code extensions (such as a linter) and supporting tools. This is intentional behavior shared across features in this repository.

## Excluding pre-bundled items

Exclude a bundled **VS Code extension** by prefixing its ID with `-`, or (when supported by a feature option) disable a bundled **tool** by setting its version option to `none` (for example, `pnpmVersion`: `none`):

```json
{
    "features": {
        "ghcr.io/devcontainers/features/node:2": {
            "pnpmVersion": "none"
        }
    },
    "customizations": {
        "vscode": {
            "extensions": [ "-dbaeumer.vscode-eslint" ]
        }
    }
}
```
