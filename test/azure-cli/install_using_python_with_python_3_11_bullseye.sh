#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Check to make sure the user is vscode
check "user is vscode" whoami | grep vscode
check "version" az  --version

echo -e "\n\n🔄 Testing 'O.S'"
if cat /etc/os-release | grep -q 'PRETTY_NAME="Debian GNU/Linux 11 (bullseye)"'; then
    echo -e "\n\n✅ Passed 'O.S is Linux 11 (bullseye)'!"
else
    echo -e "\n\n❌ Failed 'O.S is other than Linux 11 (bullseye)'!"
fi


# Report result
reportResults