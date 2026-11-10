

## OS Support

This Feature should work on recent versions of Debian/Ubuntu, RedHat Enterprise Linux, Fedora, Alma, and RockyLinux distributions with the apt, yum, dnf, or microdnf package manager installed.

`bash` is required to execute the `install.sh` script.

## Additional Python versions

`additionalVersions` accepts a comma-separated list. Comma splitting is scoped to reading this list so package-manager commands keep normal shell word splitting during each installation.

## Source Verification

The feature verifies the authenticity and integrity of downloaded Python source archives. Python 3.14 and later use Sigstore (via Cosign), while earlier versions use GPG. For compatibility, verification follows a fail-open policy: unsuccessful or unavailable verification is reported as a warning and does not block installation.