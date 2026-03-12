#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib


echo -e "\n🔄 Testing 'O.S'"
if cat /etc/os-release | grep -q 'PRETTY_NAME="Debian GNU/Linux 13 (trixie)"'; then
    echo -e "\n✅ Passed 'O.S is Linux 13 (trixie)'!\n"
else
    echo -e "\n❌ Failed 'O.S is other than Linux 13 (trixie)'!\n"
fi

# Check to make sure the user is vscode
check "user is vscode" whoami | grep vscode
check "version" az  --version

# Report result
reportResults

