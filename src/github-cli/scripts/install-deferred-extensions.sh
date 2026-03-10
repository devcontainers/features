#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

set -euo pipefail

EXTENSIONS=${EXTENSIONS:-""}
INSTALL_EXTENSIONS_FROM_GIT=${INSTALL_EXTENSIONS_FROM_GIT:-${INSTALLEXTENSIONSFROMGIT:-"false"}}
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DEFERRED_EXTENSIONS_DIR="/usr/local/share/github-cli"

main() {
	install -d -m 0755 "${DEFERRED_EXTENSIONS_DIR}"
	install -m 0755 "${SCRIPT_DIR}/install-extensions.sh" "${DEFERRED_EXTENSIONS_DIR}/install-extensions.sh"
	install -m 0755 "${SCRIPT_DIR}/install-extension-from-gh.sh" "${DEFERRED_EXTENSIONS_DIR}/install-extension-from-gh.sh"
	install -m 0755 "${SCRIPT_DIR}/install-extension-from-git.sh" "${DEFERRED_EXTENSIONS_DIR}/install-extension-from-git.sh"
	install -m 0755 "${SCRIPT_DIR}/utils.sh" "${DEFERRED_EXTENSIONS_DIR}/utils.sh"
	printf 'EXTENSIONS=%q\n' "${EXTENSIONS}" > "${DEFERRED_EXTENSIONS_DIR}/extensions.env"
	printf 'INSTALL_EXTENSIONS_FROM_GIT=%q\n' "${INSTALL_EXTENSIONS_FROM_GIT}" >> "${DEFERRED_EXTENSIONS_DIR}/extensions.env"
	chmod 0644 "${DEFERRED_EXTENSIONS_DIR}/extensions.env"
}

main "$@"