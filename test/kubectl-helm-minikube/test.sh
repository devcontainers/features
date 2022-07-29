#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "kube" kubectl
check "helm" helm version

# Report result
reportResults