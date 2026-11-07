
# AWS CLI (aws-cli)

Installs the AWS CLI along with needed dependencies. Useful for base Dockerfiles that often are missing required install dependencies like gpg.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/aws-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter an AWS CLI version. | string | latest |
| verbose | Suppress verbose output. | boolean | true |
| installSessionManagerPlugin | Install the AWS Session Manager plugin, selecting the package for the container OS and architecture. | boolean | false |

## Customizations

### VS Code Extensions

- `AmazonWebServices.aws-toolkit-vscode`

Available versions of the AWS CLI can be found here: https://github.com/aws/aws-cli/blob/v2/CHANGELOG.rst.

## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.

## Session Manager Plugin

Set `installSessionManagerPlugin` to `true` to also install the [AWS Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html). The package is chosen from `/etc/os-release` and the machine architecture: `.deb` for Debian/Ubuntu and `.rpm` for RHEL-family distributions (x86_64 and arm64). The option defaults to `false`.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/aws-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
