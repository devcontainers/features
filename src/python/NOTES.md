

## OS Support

This Feature should work on recent versions of Debian/Ubuntu, RedHat Enterprise Linux, Fedora, Alma, and RockyLinux distributions with the apt, yum, dnf, or microdnf package manager installed.

`bash` is required to execute the `install.sh` script.

## Mantainance notes

Python 3.14+ transitioned from GPG to Sigstore for source archive verification. The Cosign version is intentionally pinned to balance security and maintenance overhead; review the pin periodically and update it, along with its checksums, when upstream vulnerabilities or significant releases warrant it.

