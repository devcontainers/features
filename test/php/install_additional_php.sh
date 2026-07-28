#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "php version 8.5.0 installed as default" php --version | grep 8.5.0
check "php version 8.4.15 installed"   ls -l /usr/local/php | grep 8.4.15

check "composer-version" composer --version

# Report result
reportResults
