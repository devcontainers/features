
# AWS CLI (aws-cli)

Installs the AWS CLI along with needed dependencies. Useful for base Dockerfiles that often are missing required install dependencies like gpg.

## Example Usage

```json
"features": {
    "ghcr.io/braechnov/features/aws-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter an AWS CLI version. | string | latest |

Available versions of the AWS CLI can be found here: https://github.com/aws/aws-cli/blob/v2/CHANGELOG.rst.

## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/braechnov/features/blob/main/src/aws-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
