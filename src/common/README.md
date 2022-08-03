
# Common Debian (common)

Installs a set of common command line utilities, Oh My Zsh!, and sets up a non-root user.

## Example Usage

```json
"features": {
        "ghcr.io/devcontainers/features/common:1": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| install_Zsh | Install ZSH? | boolean | true |
| install_Oh_My_Zsh | Install Oh My Zsh!? | boolean | true |
| upgrade_packages | Upgrade OS packages? | boolean | true |
| username | Enter name of non-root user to configure or none to skip | string | automatic |
| user_uid | Enter uid for non-root user | string | automatic |
| user_gid | Enter gid for non-root user | string | automatic |
| add_non_free_packages | Add packages from non-free Debian repository? | boolean | - |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](./devcontainer-feature.json)._
