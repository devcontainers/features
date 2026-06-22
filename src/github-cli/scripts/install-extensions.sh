#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

set -euo pipefail

EXTENSIONS=${EXTENSIONS:-""}
INSTALL_EXTENSIONS_FROM_GIT=${INSTALL_EXTENSIONS_FROM_GIT:-"false"}
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly GH_EXTENSION_INSTALLER_SCRIPT="${SCRIPT_DIR}/install-extension-from-gh.sh"
readonly GIT_EXTENSION_INSTALLER_SCRIPT="${SCRIPT_DIR}/install-extension-from-git.sh"

# shellcheck source=./utils.sh
source "${SCRIPT_DIR}/utils.sh"

ensure_helper_scripts_exist() {
	if [ ! -x "${GIT_EXTENSION_INSTALLER_SCRIPT}" ] || [ ! -x "${GH_EXTENSION_INSTALLER_SCRIPT}" ]; then
		die "Missing GitHub CLI extension helper scripts in '${SCRIPT_DIR}'."
	fi
}

install_with_gh() {
	local extension="$1"
	EXTENSION="${extension}" bash "${GH_EXTENSION_INSTALLER_SCRIPT}"
}

install_with_git() {
	local extension="$1"
	EXTENSION="${extension}" bash "${GIT_EXTENSION_INSTALLER_SCRIPT}"
}

install_extension() {
	local extension="$1"

	if is_true "${INSTALL_EXTENSIONS_FROM_GIT}"; then
		install_with_git "${extension}"
		return
	fi

	if install_with_gh "${extension}"; then
		return
	fi

	err "'gh extension install ${extension}' is unavailable, falling back to git clone."
	install_with_git "${extension}"
}

run_as_target_user_if_needed() {
	local target_username
	local extensions_escaped
	local install_extensions_from_git_escaped
	local username_escaped
	local script_escaped

	if [ "$(id -u)" -ne 0 ]; then
		return
	fi

	target_username="$(resolve_target_username)"
	if [ "${target_username}" = "root" ]; then
		return
	fi

	extensions_escaped="$(printf '%q' "${EXTENSIONS}")"
	install_extensions_from_git_escaped="$(printf '%q' "${INSTALL_EXTENSIONS_FROM_GIT}")"
	username_escaped="$(printf '%q' "${target_username}")"
	script_escaped="$(printf '%q' "${BASH_SOURCE[0]}")"
	su - "${target_username}" -c "EXTENSIONS=${extensions_escaped} INSTALL_EXTENSIONS_FROM_GIT=${install_extensions_from_git_escaped} USERNAME=${username_escaped} bash ${script_escaped}"
	exit 0
}

main() {
	local extension
	local extension_list

	if [ -z "${EXTENSIONS}" ]; then
		exit 0
	fi

	ensure_helper_scripts_exist
	run_as_target_user_if_needed

	echo "Installing GitHub CLI extensions: ${EXTENSIONS}"
	IFS=',' read -r -a extension_list <<< "${EXTENSIONS}"
	for extension in "${extension_list[@]}"; do
		extension="$(trim "${extension}")"
		if [ -z "${extension}" ]; then
			continue
		fi

		install_extension "${extension}"
	done
}

main "$@"
