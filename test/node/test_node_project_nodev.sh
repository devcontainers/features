#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

cd test_node_project_nodev/sample-node

# Check that .nvmrc exists
if [ ! -f .node-version ]; then
  echo ".node-version file not found!"
  exit 1
fi

# Read the version from .nvmrc and compare with current node version
N_VERSION=$(cat .node-version | tr -d 'v')
NODE_VERSION=$(node -v  | tr -d 'v')

if [ "$N_VERSION" != "$NODE_VERSION" ]; then
  echo "Node version mismatch: .node-version specifies $N_VERSION, but current node is $NODE_VERSION"
  exit 1
fi

echo ".node-version is used and matches the current Node.js version."
# Report result
reportResults