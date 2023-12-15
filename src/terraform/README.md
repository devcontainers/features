
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
| tflint | Tflint version (https://github.com/terraform-linters/tflint/releases) | string | latest |
| terragrunt | Terragrunt version | string | latest |
| installSentinel | Install sentinel, a language and framework for policy built to be embedded in existing software to enable fine-grained, logic-based policy decisions | boolean | false |
| installTFsec | Install tfsec, a tool to spot potential misconfigurations for your terraform code | boolean | false |
| installTerraformDocs | Install terraform-docs, a utility to generate documentation from Terraform modules | boolean | false |
| httpProxy | Connect to a keyserver using a proxy by configuring this option | string | - |

## Customizations

### VS Code Extensions

- `HashiCorp.terraform`
- `ms-azuretools.vscode-azureterraform`



## Licensing

On August 10, 2023, HashiCorp announced a change of license for its products, including Terraform. After ~9 years of Terraform being open source under the MPL v2 license, it was to move under a non-open source BSL v1.1 license, starting from the next (1.6) version. See https://github.com/hashicorp/terraform/blob/main/LICENSE

## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/terraform/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
