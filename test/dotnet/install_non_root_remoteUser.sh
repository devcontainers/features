#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "ensure i am user codespace"  bash -c "whoami | grep 'codespace'"

./install_dotnet_7_jammy.sh

# Report result
reportResults
