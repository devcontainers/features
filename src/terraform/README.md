
# Terraform, tflint, and TFGrunt (terraform)

Installs the Terraform CLI and optionally TFLint and Terragrunt. Auto-detects latest version and installs needed dependencies.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/terraform:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Terraform version | string | latest |
| tflint | Tflint version | string | latest |
| terragrunt | Terragrunt version | string | latest |
| installTFsec | Install tfsec, a tool to spot potential misconfigurations for your terraform code | boolean | false |
| installTerraformDocs | Install terraform-docs, a utility to generate documentation from Terraform modules | boolean | false |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/terraform/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
