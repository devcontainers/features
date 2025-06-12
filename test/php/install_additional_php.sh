#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "php version 8.4.2 installed as default" php --version | grep 8.4.2
check "php version 8.3.14 installed"   ls -l /usr/local/php | grep 8.3.14
check "php version 8.2.27 installed"  ls -l /usr/local/php | grep 8.2.27

check "composer-version" composer --version

# Report result
reportResults
