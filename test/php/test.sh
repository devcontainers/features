#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "PHP version" php --version
check "Mbstring loaded" php -r "extension_loaded('mbstring') || throw new Error('Extension Mbstring is not loaded');"
check "composer-version" composer --version

# Report result
reportResults