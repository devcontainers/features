#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "php-version-8-is-installed" bash -c "php --version | grep '8.'"
check "php-xdebug-extension-installed" bash -c "php -m | grep 'xdebug'"
check "php-redis-extension-installed" bash -c "php -m | grep 'redis'"

# Report result
reportResults
