#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Extension-specific tests
check "pwsh file is symlink" bash -c "[ -L /usr/bin/pwsh ]"
check "pwsh symlink is registered as shell" bash -c "[ $(grep -c '/usr/bin/pwsh' /etc/shells) -eq 1 ]"
check "pwsh target is correct" bash -c "[ $(readlink /usr/bin/pwsh) = /opt/microsoft/powershell/7/pwsh ]"
check "pwsh target is registered as shell" bash -c "[ $(grep -c '/opt/microsoft/powershell/7/pwsh' /etc/shells) -eq 1 ]"
check "pwsh owner is root" bash -c "[ $(stat -c %U /opt/microsoft/powershell/7/pwsh) = root ]"
check "pwsh group is root" bash -c "[ $(stat -c %G /opt/microsoft/powershell/7/pwsh) = root ]"
check "pwsh file mode is -rwxr-xr-x" bash -c "[ $(stat -c '%A' /opt/microsoft/powershell/7/pwsh) = '-rwxr-xr-x' ]"
check "pwsh is in PATH" bash -c "command -v pwsh"

# Report result
reportResults
