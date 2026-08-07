#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

set -euo pipefail

EXTENSION=${EXTENSION:-""}
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./utils.sh
source "${SCRIPT_DIR}/utils.sh"

extension_is_required() {
	[ -n "${EXTENSION}" ]
}

gh_is_available() {
	command -v gh > /dev/null 2>&1
}

gh_is_authenticated() {
	gh auth status > /dev/null 2>&1
}

extension_is_installed() {
	gh extension list 2>/dev/null | awk '{print $1}' | grep -Fxq "${EXTENSION}"
}

main() {
	if ! extension_is_required; then
		die "EXTENSION is required for GitHub CLI extension installation."
	fi

	if ! gh_is_available; then
		die "Cannot install extension '${EXTENSION}' with 'gh': GitHub CLI is unavailable."
	fi

	if ! gh_is_authenticated; then
		die "Cannot install extension '${EXTENSION}' with 'gh': GitHub CLI is not authenticated."
	fi

	if extension_is_installed; then
		echo "Extension '${EXTENSION}' is already installed. Skipping installation."
		exit 0
	fi

	gh extension install "${EXTENSION}"
}

main "$@"