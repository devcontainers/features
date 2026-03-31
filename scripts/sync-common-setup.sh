#!/bin/bash
#-------------------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://github.com/devcontainers/features/blob/main/LICENSE for license information.
#-------------------------------------------------------------------------------------------------------------------------
#
# Script to sync common-setup.sh from the source to all feature directories
# This maintains a single source of truth while deploying to each feature for packaging
#
# Usage: ./scripts/sync-common-setup.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# The source of truth for common-setup.sh
SOURCE_FILE="${REPO_ROOT}/scripts/lib/common-setup.sh"

# Features that use the common-setup helper
# Note: common-utils is excluded because it creates users (different semantics)
FEATURES=(
    "anaconda"
    "conda"
    "desktop-lite"
    "docker-in-docker"
    "docker-outside-of-docker"
    "go"
    "hugo"
    "java"
    "kubectl-helm-minikube"
    "node"
    "oryx"
    "php"
    "python"
    "ruby"
    "rust"
    "sshd"
)

echo "Syncing common-setup.sh to all features..."
echo "Source: ${SOURCE_FILE}"
echo ""

if [ ! -f "${SOURCE_FILE}" ]; then
    echo "Error: Source file not found: ${SOURCE_FILE}"
    exit 1
fi

UPDATED_COUNT=0

for feature in "${FEATURES[@]}"; do
    TARGET_FILE="${REPO_ROOT}/src/${feature}/common-setup.sh"
    
    # Copy the file
    cp "${SOURCE_FILE}" "${TARGET_FILE}"
    
    echo "✓ Synced to src/${feature}/common-setup.sh"
    UPDATED_COUNT=$((UPDATED_COUNT + 1))
done

echo ""
echo "======================================"
echo "Sync complete!"
echo "Updated ${UPDATED_COUNT} features"
echo "======================================"
echo ""
echo "Note: These files are .gitignored and generated at CI time."
echo "This script is called automatically by CI workflows before packaging."
