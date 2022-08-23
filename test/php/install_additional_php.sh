#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "php version 8.1.4 installed as default" php --version | grep 8.1.4
check "php version 8.0.17 installed"   ls -l /usr/local/php | grep 8.0.17
check "php version 8.0.3 installed"  ls -l /usr/local/php | grep 8.0.3

# Report result
reportResults
