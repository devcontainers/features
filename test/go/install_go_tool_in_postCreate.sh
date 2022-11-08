#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "mkcert version" bash -c "mkcert --version | grep 'v1.4.2'"
check "mkcert is installed at correct path" which mkcert | grep "/go/bin/mkcert"
check "golangci-lint version" golangci-lint --version | grep "golangci-lint has version 1.50.0"

# Report result
reportResults
