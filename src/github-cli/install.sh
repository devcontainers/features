#!/usr/bin/env sh
# shellcheck shell=sh
#
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/github-cli
# Maintainer: The VS Code and Codespaces Teams

set -eu

EXTENSIONS="${EXTENSIONS:-}"
CLI_VERSION="${VERSION:-latest}"
INSTALL_DIRECTLY_FROM_GITHUB_RELEASE="${INSTALLDIRECTLYFROMGITHUBRELEASE:-true}"

SCRIPTS_DIR="$(readlink -f "$(dirname "$(readlink -f "${0}")")/scripts")"
EXTENSIONS_SCRIPT="$(readlink -f "${SCRIPTS_DIR}/install-extensions.sh")"
COMMON_UTILS="$(readlink -f "${SCRIPTS_DIR}/common.sh")"

export EXTENSIONS CLI_VERSION SCRIPTS_DIR COMMON_UTILS EXTENSIONS_SCRIPT INSTALL_DIRECTLY_FROM_GITHUB_RELEASE

# shellcheck source-path=SCRIPTDIR source=scripts/common.sh
. "${COMMON_UTILS}"

require_root

# determine what kind of base image we're running in

# The base image's OS identifiers, one per line, most specific first: ID, then each entry of
# ID_LIKE - which is a whitespace-separated list, e.g. ID_LIKE="rhel centos fedora".
#
# Values may be bare, double-quoted or single-quoted, and the file may carry comments, other
# keys whose values contain "=", or CRLF line endings, so parse defensively.
os_ids() {
  if [ ! -f /etc/os-release ]; then
    echo '(!) Base image has no /etc/os-release file!' >&2

    # return nothing to indicate 'unknown'
    return
  fi

  detected_ids="$(
    awk '
      function clean(value) {
        sub(/\r$/, "", value)
        sub(/^[ \t]+/, "", value); sub(/[ \t]+$/, "", value)
        sub(/^["\047]/, "", value); sub(/["\047]$/, "", value)
        return value
      }
      /^[ \t]*ID=/      { id   = clean(substr($0, index($0, "=") + 1)) }
      /^[ \t]*ID_LIKE=/ { like = clean(substr($0, index($0, "=") + 1)) }
      END {
        count = split(id " " like, candidate, /[ \t]+/)
        for (i = 1; i <= count; i++) {
          if (candidate[i] != "" && !(candidate[i] in seen)) {
            seen[candidate[i]] = 1
            print candidate[i]
          }
        }
      }
    ' /etc/os-release
  )"

  if [ -z "${detected_ids}" ]; then
    echo '(!) Base image /etc/os-release sets neither ID nor ID_LIKE!' >&2
  fi

  echo "${detected_ids}"
}

os_pkg_manager() {
  case "${1}" in
  debian)
    echo "dpkg"
    ;;
  alpine)
    echo "apk"
    ;;
  arch)
    echo "pacman"
    ;;
  nixos)
    echo "nix"
    ;;
  fedora | rhel | suse)
    echo "rpm"
    ;;
  *)
    # Only ever reached if an installer script was added under scripts/ without a matching
    # entry above, so say so plainly rather than blaming the base image
    echo "(!) No package manager is mapped for OS '${1}', which has an installer script." >&2

    # return an empty string to indicate "no predetermined OS ⟺ package manager pair"
    echo ""
    ;;
  esac
}

base_os_name() {
  candidates="$(os_ids)"

  if [ -z "${candidates}" ]; then
    exit 1
  fi

  # Waterfall from most specific to least: the first candidate we actually ship an installer
  # for wins, so an Ubuntu derivative falls through `pop` and `ubuntu` to land on `debian`.
  matched_os=""
  for candidate in ${candidates}; do
    if [ -f "${SCRIPTS_DIR}/${candidate}/install.sh" ]; then
      matched_os="${candidate}"
      break
    fi
  done

  if [ -z "${matched_os}" ]; then
    # Name the base image by its own ID rather than by whatever it claims to be like
    primary_id="$(printf '%s\n' "${candidates}" | head -n 1)"
    {
      # shellcheck disable=SC2016
      printf '`github-cli` feature for %s-based devcontainers not yet implemented! ' "${primary_id}"
      printf 'Contributions are welcome; please implement %s support ' "${primary_id}"
      printf 'and open a pull request to https://github.com/devcontainers/features.git\n'
    } >&2

    exit 1
  fi

  manager_cmd="$(os_pkg_manager "${matched_os}")"

  if [ -z "${manager_cmd}" ]; then
    exit 1
  fi

  if ! command -v "${manager_cmd}" >/dev/null 2>&1; then
    {
      printf "(!) Base image reports OS '%s', but its expected package manager " "${matched_os}"
      printf "('%s') is not installed. Declining to install in uncertain environment.\\n" "${manager_cmd}"
    } >&2

    exit 1
  fi

  echo "${matched_os}"
}

# base_os_name only ever returns an OS we ship a usable installer for
base_os="$(base_os_name)"
installer="${SCRIPTS_DIR}/${base_os}/install.sh"

# The per-OS installers are only responsible getting `gh` onto the PATH (and,
# where the base image lacks it, bash for the extensions script). Everything
# that follows is the same on every distro, so it is orchestrated here rather
# than duplicated in each installer.
"${installer}"

if [ -n "${EXTENSIONS}" ]; then
  resolve_username
  install_gh_extensions
fi
