
# common (common)

common

## Example Usage

```json
"features": [
    "common": {
        "id": "devcontainers/features/#{featureId}@latest",
        "options": {
            "version": "latest"
        }
    }
]
```

## Options

| Options Id | Description | Type | Default Value ||-----|-----|-----|-----|
| install_Zsh | Install ZSH? | boolean | true |
| install_Oh_My_Zsh | Install Oh My Zsh!? | boolean | true |
| upgrade_packages | Upgrade OS packages? | boolean | true |
| username | Enter name of non-root user to configure or none to skip | string | automatic |
| user_uid | Enter uid for non-root user | string | automatic |
| user_gid | Enter gid for non-root user | string | automatic |
| add_non_free_packages | Add packages from non-free Debian repository? | boolean | - |

---

_Note: This is an auto-generated file. Please do not directly edit._
