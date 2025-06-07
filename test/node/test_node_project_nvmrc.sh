#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

cd test_node_project_nvmrc/sample-node

# Check that .nvmrc exists
if [ ! -f .nvmrc ]; then
  echo ".nvmrc file not found!"
  exit 1
fi

# Read the version from .nvmrc and compare with current node version
NVMRC_VERSION=$(cat .nvmrc | tr -d 'v')
NODE_VERSION=$(node -v  | tr -d 'v')

if [ "$NVMRC_VERSION" != "$NODE_VERSION" ]; then
  echo "Node version mismatch: .nvmrc specifies $NVMRC_VERSION, but current node is $NODE_VERSION"
  exit 1
fi

echo ".nvmrc is used and matches the current Node.js version."
# Report result
reportResults