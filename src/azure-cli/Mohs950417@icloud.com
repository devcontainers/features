{
  "id": "azure-cli",
  "version": "1.2.9",
  "name": "Azure CLI",
  "documentationURL": "https://github.com/devcontainers/features/tree/main/src/azure-cli",
  "description": "Installs the Azure CLI along with needed dependencies. Useful for base Dockerfiles that often are missing required install dependencies like gpg.",
  "options": {
    "version": {
      "type": "string",
      "proposals": [
        "latest"
      ],
      "default": "latest",
      "description": "Select or enter an Azure CLI version. (Available versions may vary by Linux distribution.)"
    },
    "extensions": {
      "type": "string",
      "default": "",
      "description": "Optional comma separated list of Azure CLI extensions to install in profile."
    },
    "installBicep": {
      "type": "boolean",
      "description": "Optionally install Azure Bicep",
      "default": false
    },
    "bicepVersion": {
      "type": "string",
      "proposals": [
        "latest"
      ],
      "default": "latest",
      "description": "Select or enter a Bicep version. ('latest' or a specic version such as 'v0.31.92')"
    },
    "installUsingPython": {
      "type": "boolean",
      "description": "Install Azure CLI using Python instead of pipx",
      "default": false
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.azurecli"
      ],
      "settings": {
        "github.copilot.chat.codeGeneration.instructions": [
          {
            "text": "This dev container includes the Azure CLI along with needed dependencies pre-installed and available on the `PATH`, along with the Azure CLI extension for Azure development."
          }
        ]
      }
    }
  },
  "installsAfter": [
    "ghcr.io/devcontainers/features/common-utils"
  ]
}
