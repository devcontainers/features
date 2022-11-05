#!/bin/bash
set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

uid="$(id -u)"
echo "Current user UID is ${uid}."
nix_uid="$(stat /nix -c "%u")"
echo "/nix UID is ${nix_uid}."

cat /etc/os-release

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "nix-env" type nix-env
check "install" nix-env --install vim
check "vim_installed" type vim

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults &2>1