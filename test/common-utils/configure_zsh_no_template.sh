#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
function file_not_overridden() {
    cat ~/.zshrc | grep 'alias fnomockalias=' | grep testingmock
}
check "default-zsh-with-no-zshrc" file_not_overridden

# Report result
reportResults
