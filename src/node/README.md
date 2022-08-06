
# Node.js (via nvm) and yarn (node)

Installs Node.js, nvm, yarn, and needed dependencies.

## Example Usage

```json
"features": {
        "devcontainers/features/node@latest": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a Node.js version to install | string | lts |
| install_tools_for_node_gyp | Install dependencies to compile native node modules (node-gyp)? | boolean | true |
| nvm_install_path | The path where NVM will be installed. | string | /usr/local/share/nvm |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/node/devcontainer-feature.json)._
