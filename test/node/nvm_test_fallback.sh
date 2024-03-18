#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

set -e

trap 'echo "Error occurred at line $LINENO"; exit 1' ERR
source /usr/local/share/nvm/nvm.sh
#check nvm version
echo -e "\n✅ nvm version as installed by feature = v$(nvm --version)";
NVM_DIR="/usr/local/share/nvm"
NODE_VERSION="lts"
FAKE_NVM_VERSION="1.2.XYZ"
curl -so- "https://raw.githubusercontent.com/nvm-sh/nvm/v${FAKE_NVM_VERSION}/install.sh" | bash ||  {
    PREV_NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    curl -so- "https://raw.githubusercontent.com/nvm-sh/nvm/${PREV_NVM_VERSION}/install.sh" | bash
    NVM_VERSION="${PREV_NVM_VERSION}"
}

#check nvm version
echo -e "\n✅ nvm version as installed by test = v$(nvm --version)";

# Report result
reportResults
