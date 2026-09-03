#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# golangci is a smoke test to ensure the go install directory doesn't have leftover files from 1.22
check "install golangci-lint to verify the go install" bash -c "go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.56.2"

# Report result
reportResults
