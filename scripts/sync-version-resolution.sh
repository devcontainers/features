#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="${ROOT_DIR}/scripts/version-resolution.sh"
FEATURES=(
    copilot-cli
    docker-in-docker
    docker-outside-of-docker
    git-lfs
    github-cli
    go
    kubectl-helm-minikube
    nix
    node
    php
    powershell
    python
    rust
    terraform
)

check_only=false
if [ "${1:-}" = "--check" ]; then
    check_only=true
fi

for feature in "${FEATURES[@]}"; do
    target_dir="${ROOT_DIR}/src/${feature}/scripts"
    target_file="${target_dir}/version-resolution.sh"
    if ${check_only}; then
        if ! cmp -s "${SOURCE_FILE}" "${target_file}"; then
            echo "${target_file} is not synchronized with ${SOURCE_FILE}." >&2
            exit 1
        fi
    else
        mkdir -p "${target_dir}"
        cp "${SOURCE_FILE}" "${target_file}"
    fi
done