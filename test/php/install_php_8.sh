#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "php-version-8-is-installed" php --version | grep '8.'

# Report result
reportResults
