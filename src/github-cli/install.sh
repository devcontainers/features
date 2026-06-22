#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/github.md
# Maintainer: The VS Code and Codespaces Teams

set -euo pipefail

EXTENSIONS=${EXTENSIONS:-""}
INSTALL_EXTENSIONS_FROM_GIT=${INSTALL_EXTENSIONS_FROM_GIT:-${INSTALLEXTENSIONSFROMGIT:-"false"}}
AUTH_ON_SETUP=${AUTHONSETUP:-"false"}
DEFER_EXTENSIONS_UNTIL_AUTH=false
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPTS_DIR="${SCRIPT_DIR}/scripts"

# shellcheck source=./scripts/utils.sh
source "${SCRIPTS_DIR}/utils.sh"

has_unsupported_extensions_configuration() {
    [ -n "${EXTENSIONS}" ] && ! is_true "${AUTH_ON_SETUP}" && ! is_true "${INSTALL_EXTENSIONS_FROM_GIT}"
}

validate_configuration() {
    if has_unsupported_extensions_configuration; then
        die "Unsupported extensions configuration. When 'extensions' is set, enable 'authOnSetup' to install after authentication or set 'installExtensionsFromGit' to true to clone extensions during feature setup."
    fi
}

should_defer_extensions_until_auth() {
    [ -n "${EXTENSIONS}" ] && is_true "${AUTH_ON_SETUP}" && ! is_true "${INSTALL_EXTENSIONS_FROM_GIT}"
}

run_scope() {
    local scope="$1"
    local scope_script="${SCRIPTS_DIR}/install-${scope}.sh"

    if [ ! -f "${scope_script}" ]; then
        die "Missing scope installer: ${scope_script}"
    fi

    DEFER_EXTENSIONS_UNTIL_AUTH="${DEFER_EXTENSIONS_UNTIL_AUTH}" bash "${scope_script}"
}

cleanup_apt_lists() {
    rm -rf /var/lib/apt/lists/*
}

main() {
    if [ "$(id -u)" -ne 0 ]; then
        die 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    fi

    cleanup_apt_lists
    trap cleanup_apt_lists EXIT

    validate_configuration

    if should_defer_extensions_until_auth; then
        DEFER_EXTENSIONS_UNTIL_AUTH=true
    fi

    run_scope github-cli
    run_scope authentication

    if [ "${DEFER_EXTENSIONS_UNTIL_AUTH}" != "true" ]; then
        run_scope extensions
    fi
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
