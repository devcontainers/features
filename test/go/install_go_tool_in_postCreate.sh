#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "mkcert version" mkcert --version | grep "v1.4.2"

# Report result
reportResults
