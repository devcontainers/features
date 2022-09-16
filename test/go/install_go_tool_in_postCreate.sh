#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "mkcert version" mkcert --version | grep "v1.4.2"
check "mkcert is installed at correct path" which mkcert | grep "/usr/local/go/bin/mkcert"

# Report result
reportResults
