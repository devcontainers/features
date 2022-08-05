
# Terraform, tflint, and TFGrunt (terraform)

Installs the Terraform CLI and optionally TFLint and Terragrunt. Auto-detects latest version and installs needed dependencies.

## Example Usage

```json
"features": {
        "devcontainers/features/terraform@latest": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Terraform version | string | latest |
| tflint | Tflint version | string | latest |
| terragrunt | Terragrunt version | string | latest |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](./devcontainer-feature.json)._
