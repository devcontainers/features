#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "current user" bash -c "whoami"

check "rubies installed" bash -c "rvm list"

check "3.0.6 installed" bash -c "rvm list | fgrep 3.0.6"
check "2.7.8 installed" bash -c "rvm list | fgrep 2.7.8"

# Report result
reportResults