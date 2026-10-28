Available versions of the AWS CLI can be found here: https://github.com/aws/aws-cli/blob/v2/CHANGELOG.rst.

## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.

## Session Manager Plugin

Set `installSessionManagerPlugin` to `true` to also install the [AWS Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html). The package is chosen from `/etc/os-release` and the machine architecture: `.deb` for Debian/Ubuntu and `.rpm` for RHEL-family distributions (x86_64 and arm64). The option defaults to `false`.
