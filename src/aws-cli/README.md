
# AWS CLI (aws-cli)

Installs the AWS CLI along with needed dependencies. Useful for base Dockerfiles that often are missing required install dependencies like gpg.

## Example Usage

```json
"features": {
        "ghcr.io/devcontainers/features/aws-cli:latest": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter an AWS CLI version. (Available versions here: https://github.com/aws/aws-cli/blob/v2/CHANGELOG.rst) | string | latest |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](./devcontainer-feature.json)._
