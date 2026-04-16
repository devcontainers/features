#!/usr/bin/env bash

set -euo pipefail

MARKER_FILE="${HOME}/.config/vscode-dev-containers/github-cli-auth-already-ran"
RESOLVED_AUTH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
DEFERRED_EXTENSIONS_ENV=/usr/local/share/github-cli/extensions.env
DEFERRED_EXTENSIONS_SCRIPT=/usr/local/share/github-cli/install-extensions.sh

is_auth_setup_complete() {
	[ -f "${MARKER_FILE}" ]
}

mark_auth_setup_complete() {
	mkdir -p "$(dirname "${MARKER_FILE}")"
	touch "${MARKER_FILE}"
}

is_gh_available() {
	command -v gh > /dev/null 2>&1
}

is_authenticated() {
	gh auth status > /dev/null 2>&1
}

has_deferred_extensions() {
	[ -f "${DEFERRED_EXTENSIONS_ENV}" ] && [ -x "${DEFERRED_EXTENSIONS_SCRIPT}" ]
}

clear_deferred_extensions_config() {
	rm -f "${DEFERRED_EXTENSIONS_ENV}" >/dev/null 2>&1 || true
}

install_deferred_extensions() {
	if ! has_deferred_extensions; then
		return 0
	fi

	# shellcheck disable=SC1090
	. "${DEFERRED_EXTENSIONS_ENV}"

	if [ -z "${EXTENSIONS:-}" ]; then
		return 0
	fi

	EXTENSIONS="${EXTENSIONS}" INSTALL_EXTENSIONS_FROM_GIT="${INSTALL_EXTENSIONS_FROM_GIT:-false}" bash "${DEFERRED_EXTENSIONS_SCRIPT}"
}

run_deferred_extensions_if_present() {
	if install_deferred_extensions; then
		clear_deferred_extensions_config
		return 0
	fi

	return 1
}

attempt_login() {
	if [ -n "${RESOLVED_AUTH_TOKEN}" ]; then
		printf '%s' "${RESOLVED_AUTH_TOKEN}" | gh auth login --with-token > /dev/null 2>&1 || true
		return
	fi

	if [ -t 0 ] && [ -t 1 ]; then
		gh auth login || true
	fi
}

main() {
	if is_auth_setup_complete || ! is_gh_available; then
		exit 0
	fi

	if is_authenticated; then
		if ! run_deferred_extensions_if_present; then
			exit 0
		fi
		mark_auth_setup_complete
		exit 0
	fi

	attempt_login

	if is_authenticated && run_deferred_extensions_if_present; then
		mark_auth_setup_complete
	fi
}

main

exit 0