#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "devcontainer-info version" sh -c "devcontainer-info | grep test-version"
check "devcontainer-info id" sh -c "devcontainer-info | grep test-build"
check "devcontainer-info variant" sh -c "devcontainer-info | grep test-variant"
check "devcontainer-info repository" sh -c "devcontainer-info | grep test-repository"
check "devcontainer-info release" sh -c "devcontainer-info | grep test-release"
check "devcontainer-info revigion" sh -c "devcontainer-info | grep test-revision"
check "devcontainer-info timestamp" sh -c "devcontainer-info | grep test-time"
check "devcontainer-info url" sh -c "devcontainer-info | grep test-url"

# Report result
reportResults
