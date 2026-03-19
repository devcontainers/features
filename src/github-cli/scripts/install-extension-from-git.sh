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

get_extensions_root() {
	echo "${XDG_DATA_HOME:-"${HOME}/.local/share"}/gh/extensions"
}

extension_is_required() {
	[ -n "${EXTENSION}" ]
}

target_dir() {
	echo "$(get_extensions_root)/${EXTENSION##*/}"
}

extension_is_installed() {
	[ -d "$(target_dir)" ]
}

main() {
	local extensions_root
	local install_target

	if ! extension_is_required; then
		die "EXTENSION is required for git-based GitHub CLI extension installation."
	fi

	if ! command -v git > /dev/null 2>&1; then
		die "Cannot install extension '${EXTENSION}' because git is unavailable."
	fi

	if extension_is_installed; then
		echo "Extension '${EXTENSION}' is already installed. Skipping installation."
		exit 0
	fi

	extensions_root="$(get_extensions_root)"
	install_target="$(target_dir)"

	mkdir -p "${extensions_root}"
	git clone --depth 1 "https://github.com/${EXTENSION}.git" "${install_target}"
}

main "$@"