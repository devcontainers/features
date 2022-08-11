
# Common Debian Utilities (common-utils)

Installs a set of common command line utilities, Oh My Zsh!, and sets up a non-root user.

## Example Usage

```json
"features": {
        "ghcr.io/devcontainers/features/common-utils:1": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| installZsh | Install ZSH? | boolean | true |
| installOhMyZsh | Install Oh My Zsh!? | boolean | true |
| upgradePackages | Upgrade OS packages? | boolean | true |
| username | Enter name of non-root user to configure or none to skip | string | automatic |
| uid | Enter uid for non-root user | string | automatic |
| gid | Enter gid for non-root user | string | automatic |
| nonFreePackages | Add packages from non-free Debian repository? | boolean | - |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/common-utils/devcontainer-feature.json)._
