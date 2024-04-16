#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib


echo -e "\n🔄 Testing 'O.S'"
if cat /etc/os-release | grep -q 'PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"'; then
    echo -e "\n✅ Passed 'O.S is Linux 12 (bookworm)'!\n"
else
    echo -e "\n❌ Failed 'O.S is other than Linux 12 (bookworm)'!\n"
fi

# Check to make sure the user is vscode
check "user is vscode" whoami | grep vscode
check "version" az  --version

# Report result
reportResults