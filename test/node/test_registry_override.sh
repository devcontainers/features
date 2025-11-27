#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Check if env var is set
check "NVM_NODEJS_ORG_MIRROR is set" bash -c "echo $NVM_NODEJS_ORG_MIRROR | grep 'https://nodejs.org/dist'"

# Check if nvm can list remote versions (verifies network/config is vaguely sane)
check "nvm ls-remote" bash -c ". /usr/local/share/nvm/nvm.sh && nvm ls-remote | head"

reportResults
