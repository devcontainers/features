
# Node.js (via nvm) and yarn (node)



## Example Usage

```json
"features": [
    "node": {
        "id": "devcontainers/features/#{featureId}@latest",
        "options": {
            "version": "latest"
        }
    }
]
```

## Options

| Options Id | Description | Type | Default Value ||-----|-----|-----|-----|
| version | Select or enter a Node.js version to install | string | lts |
| install_tools_for_node_gyp | Install dependencies to compile native node modules (node-gyp)? | boolean | true |
| nvm_install_path | The path where NVM will be installed. | string | /usr/local/share/nvm |

---

_Note: This is an auto-generated file. Please do not directly edit._
