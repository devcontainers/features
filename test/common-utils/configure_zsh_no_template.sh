#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
# alias added due to scenario initializeCommand, check its still there, thus 
# file not been overridden. testing querk
function check_not_overridden() {
    cat ~/.zsh | grep 'alias testingmock' | grep 'testingmock' 
}
check "check-file-has-not-been-overridden" check_not_overridden

# Report result
reportResults
