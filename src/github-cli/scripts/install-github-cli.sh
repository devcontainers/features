#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

set -euo pipefail

CLI_VERSION=${VERSION:-"latest"}
INSTALL_DIRECTLY_FROM_GITHUB_RELEASE=${INSTALLDIRECTLYFROMGITHUBRELEASE:-"true"}

GITHUB_CLI_ARCHIVE_GPG_KEY=23F3D4EA75716059
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./utils.sh
source "${SCRIPT_DIR}/utils.sh"

get_gpg_key_servers() {
	declare -A keyservers_curl_map=(
		["hkp://keyserver.ubuntu.com"]="http://keyserver.ubuntu.com:11371"
		["hkp://keyserver.ubuntu.com:80"]="http://keyserver.ubuntu.com"
		["hkps://keys.openpgp.org"]="https://keys.openpgp.org"
		["hkp://keyserver.pgp.com"]="http://keyserver.pgp.com:11371"
	)

	local curl_args=""
	local keyserver
	local keyserver_curl_url
	local keyserver_reachable=false

	if [ -n "${KEYSERVER_PROXY:-}" ]; then
		curl_args="--proxy ${KEYSERVER_PROXY}"
	fi

	for keyserver in "${!keyservers_curl_map[@]}"; do
		keyserver_curl_url="${keyservers_curl_map[${keyserver}]}"
		if curl -s ${curl_args} --max-time 5 "${keyserver_curl_url}" > /dev/null; then
			echo "keyserver ${keyserver}"
			keyserver_reachable=true
		else
			echo "(*) Keyserver ${keyserver} is not reachable." >&2
		fi
	done

	if [ "${keyserver_reachable}" != "true" ]; then
		die "No keyserver is reachable."
	fi
}

receive_gpg_keys() {
	local keys=${!1}
	local keyring_args=""
	local retry_count=0
	local gpg_ok="false"

	if [ -n "${2:-}" ]; then
		keyring_args="--no-default-keyring --keyring $2"
	fi

	if ! command -v curl > /dev/null 2>&1; then
		check_packages curl
	fi

	export GNUPGHOME="/tmp/tmp-gnupg"
	mkdir -p "${GNUPGHOME}"
	chmod 700 "${GNUPGHOME}"
	echo -e "disable-ipv6\n$(get_gpg_key_servers)" > "${GNUPGHOME}/dirmngr.conf"

	set +e
	until [ "${gpg_ok}" = "true" ] || [ "${retry_count}" -eq "5" ]; do
		echo "(*) Downloading GPG key..."
		(echo "${keys}" | xargs -n 1 gpg -q ${keyring_args} --recv-keys) 2>&1 && gpg_ok="true"
		if [ "${gpg_ok}" != "true" ]; then
			echo "(*) Failed getting key, retrying in 10s..."
			retry_count=$((retry_count + 1))
			sleep 10s
		fi
	done
	set -e

	if [ "${gpg_ok}" = "false" ]; then
		die "Failed to get gpg key."
	fi
}

apt_get_update() {
	if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
		echo "Running apt-get update..."
		apt-get update -y
	fi
}

check_packages() {
	if ! dpkg -s "$@" > /dev/null 2>&1; then
		apt_get_update
		apt-get -y install --no-install-recommends "$@"
	fi
}

find_version_from_git_tags() {
	local variable_name=$1
	local requested_version=${!variable_name}
	local repository=$2
	local prefix=${3:-"tags/v"}
	local separator=${4:-"."}
	local last_part_optional=${5:-"false"}
	local escaped_separator
	local last_part
	local regex
	local version_list=""

	if [ "${requested_version}" = "none" ]; then
		return
	fi

	if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
		escaped_separator=${separator//./\\.}
		if [ "${last_part_optional}" = "true" ]; then
			last_part="(${escaped_separator}[0-9]+)?"
		else
			last_part="${escaped_separator}[0-9]+"
		fi
		regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${last_part}$"
		version_list="$(git ls-remote --tags "${repository}" | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
		if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
			declare -g "${variable_name}=$(echo "${version_list}" | head -n 1)"
		else
			set +e
			declare -g "${variable_name}=$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
			set -e
		fi
	else
		version_list="${requested_version}"
	fi

	if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep -q "^${!variable_name//./\\.}$"; then
		err "Invalid ${variable_name} value: ${requested_version}"
		err "Valid values:"
		printf '%s\n' "${version_list}" >&2
		exit 1
	fi
}

find_prev_version_from_git_tags() {
	local variable_name=$1
	local current_version=${!variable_name}
	local repository=$2
	local prefix=${3:-"tags/v"}
	local separator=${4:-"."}
	local last_part_optional=${5:-"false"}
	local major
	local minor
	local breakfix

	set +e
	major="$(echo "${current_version}" | grep -oE '^[0-9]+' || echo '')"
	minor="$(echo "${current_version}" | grep -oP '^[0-9]+\.\K[0-9]+' || echo '')"
	breakfix="$(echo "${current_version}" | grep -oP '^[0-9]+\.[0-9]+\.\K[0-9]+' 2>/dev/null || echo '')"

	if [ "${minor}" = "0" ] && [ "${breakfix}" = "0" ]; then
		major=$((major - 1))
		declare -g "${variable_name}=${major}"
		find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
	elif [ -z "${breakfix}" ] || [ "${breakfix}" = "0" ]; then
		minor=$((minor - 1))
		declare -g "${variable_name}=${major}.${minor}"
		find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
	else
		breakfix=$((breakfix - 1))
		if [ "${breakfix}" = "0" ] && [ "${last_part_optional}" = "true" ]; then
			declare -g "${variable_name}=${major}.${minor}"
		else
			declare -g "${variable_name}=${major}.${minor}.${breakfix}"
		fi
	fi
	set -e
}

install_deb_using_github() {
	local arch
	local cli_filename
	local exit_code

	check_packages wget
	arch="$(dpkg --print-architecture)"

	find_version_from_git_tags CLI_VERSION https://github.com/cli/cli
	cli_filename="gh_${CLI_VERSION}_linux_${arch}.deb"

	mkdir -p /tmp/ghcli
	pushd /tmp/ghcli > /dev/null
	set +e
	wget -q --show-progress --progress=dot:giga "https://github.com/cli/cli/releases/download/v${CLI_VERSION}/${cli_filename}"
	exit_code=$?
	set -e
	if [ "${exit_code}" != "0" ]; then
		err "github-cli version ${CLI_VERSION} failed to download. Attempting to fall back one version to retry..."
		find_prev_version_from_git_tags CLI_VERSION https://github.com/cli/cli
		cli_filename="gh_${CLI_VERSION}_linux_${arch}.deb"
		wget -q --show-progress --progress=dot:giga "https://github.com/cli/cli/releases/download/v${CLI_VERSION}/${cli_filename}"
	fi

	dpkg -i "/tmp/ghcli/${cli_filename}"
	popd > /dev/null
	rm -rf /tmp/ghcli
}

main() {
	local version_suffix=""

	export DEBIAN_FRONTEND=noninteractive

	check_packages curl ca-certificates apt-transport-https dirmngr gnupg2
	if ! command -v git > /dev/null 2>&1; then
		check_packages git
	fi

	if [ "${CLI_VERSION}" != "latest" ] && [ "${CLI_VERSION}" != "lts" ] && [ "${CLI_VERSION}" != "stable" ]; then
		find_version_from_git_tags CLI_VERSION https://github.com/cli/cli
		version_suffix="=${CLI_VERSION}"
	fi

	echo "Downloading GitHub CLI..."

	if [ "${INSTALL_DIRECTLY_FROM_GITHUB_RELEASE}" = "true" ]; then
		install_deb_using_github
		return
	fi

	receive_gpg_keys GITHUB_CLI_ARCHIVE_GPG_KEY /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
	apt-get update
	apt-get -y install "gh${version_suffix}"
	rm -rf /tmp/gh/gnupg
	echo "Done!"
}

main "$@"
