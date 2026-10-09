#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

set -euo pipefail

AUTH_ON_SETUP=${AUTHONSETUP:-"false"}
DEFER_EXTENSIONS_UNTIL_AUTH=${DEFER_EXTENSIONS_UNTIL_AUTH:-"false"}
EXTENSIONS=${EXTENSIONS:-""}
INSTALL_EXTENSIONS_FROM_GIT=${INSTALL_EXTENSIONS_FROM_GIT:-${INSTALLEXTENSIONSFROMGIT:-"false"}}
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly AUTH_ON_SETUP_SCRIPT="${SCRIPT_DIR}/auth-on-setup.sh"
readonly DEFERRED_EXTENSION_INSTALLER_SCRIPT="${SCRIPT_DIR}/install-deferred-extensions.sh"
readonly INSTALLED_AUTH_ON_SETUP_SCRIPT="/usr/local/share/github-cli-auth-on-setup.sh"

updaterc() {
	local rc_content="$1"
	local rc_marker="${2:-$1}"

	if [ -f /etc/bash.bashrc ] && ! grep -Fq "${rc_marker}" /etc/bash.bashrc; then
		echo -e "${rc_content}" >> /etc/bash.bashrc
	fi

	if [ -f /etc/zsh/zshrc ] && ! grep -Fq "${rc_marker}" /etc/zsh/zshrc; then
		echo -e "${rc_content}" >> /etc/zsh/zshrc
	fi
}

main() {
	if [ "${AUTH_ON_SETUP}" != "true" ]; then
		return
	fi

	install -d -m 0755 /usr/local/share/github-cli
	install -m 0755 "${AUTH_ON_SETUP_SCRIPT}" "${INSTALLED_AUTH_ON_SETUP_SCRIPT}"
	if [ "${DEFER_EXTENSIONS_UNTIL_AUTH}" = "true" ]; then
		EXTENSIONS="${EXTENSIONS}" INSTALL_EXTENSIONS_FROM_GIT="${INSTALL_EXTENSIONS_FROM_GIT}" bash "${DEFERRED_EXTENSION_INSTALLER_SCRIPT}"
	fi
	updaterc $'# github-cli authOnSetup\nbash /usr/local/share/github-cli-auth-on-setup.sh' '# github-cli authOnSetup'
}

main "$@"
