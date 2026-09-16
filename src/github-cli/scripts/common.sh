# shellcheck shell=sh
#
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/github-cli
# Maintainer: The VS Code and Codespaces Teams
#
# Distro-agnostic helpers shared by ../install.sh and the per-OS installers alongside this
# file. Sourced, never executed: `. "${COMMON_UTILS}"`.
#
# Everything here is POSIX sh so that it can be sourced just as happily from the `sh`
# orchestrator as from a `bash` installer. Helper-local variables are `_`-prefixed rather
# than declared `local`, which is not POSIX.

# Cached by load_gh_versions so that repeated lookups do not re-hit the network. Only
# effective for calls made outside a `$(...)` subshell.
GH_VERSION_LIST=""

# Refuse to run anywhere the installers cannot actually write
require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.' >&2
    exit 1
  fi
}

# POSIX sh has no `printf %q`; single-quote the value and escape any quotes within it
shell_quote() {
  printf "'%s'" "$(printf '%s' "${1}" | sed "s/'/'\\\\''/g")"
}

# Populate GH_VERSION_LIST with every released gh version, newest first.
#
# BusyBox `grep` has no `-P` and BusyBox `sort` no `-V`, so the tags are extracted with
# `sed` and the version parts sorted numerically field by field instead. Both forms behave
# identically under GNU coreutils, so this one implementation covers every base image.
load_gh_versions() {
  if [ -z "${GH_VERSION_LIST}" ]; then
    GH_VERSION_LIST="$(
      git ls-remote --tags --refs https://github.com/cli/cli |
        sed -n 's#.*refs/tags/v\([0-9][0-9.]*\)$#\1#p' |
        sort -t. -k1,1nr -k2,2nr -k3,3nr
    )"
  fi
}

# Resolve an alias ("latest") or a partial version ("2", "2.101") to a full release number,
# rewriting the named variable in place. Fails, listing the valid values, if nothing matches.
#
# Usage: find_version_from_git_tags CLI_VERSION
find_version_from_git_tags() {
  _variable_name="${1}"
  eval "_requested_version=\${${_variable_name}}"

  load_gh_versions

  # No `exit` in the awk program: it would SIGPIPE the upstream `printf` and so trip
  # `pipefail` in the bash installers. Reading the whole list through costs nothing.
  # shellcheck disable=SC2154 # _requested_version is assigned by the eval above
  _resolved_version="$(
    printf '%s\n' "${GH_VERSION_LIST}" |
      awk -v want="${_requested_version}" '
        BEGIN { newest = (want == "latest" || want == "current" || want == "lts" || want == "stable") }
        found { next }
        # Comparing "${line}." against "${want}." anchors the match on a version-part
        # boundary, so that "2.1" does not select "2.101.0".
        newest || index($0 ".", want ".") == 1 { print; found = 1 }
      '
  )"

  if [ -z "${_resolved_version}" ]; then
    {
      echo "Invalid ${_variable_name} value: ${_requested_version}"
      echo "Valid values:"
      printf '%s\n' "${GH_VERSION_LIST}"
    } >&2
    return 1
  fi

  eval "${_variable_name}=\${_resolved_version}"
  echo "${_variable_name}=${_resolved_version}"
}

# Git tags can run ahead of what has actually been published as a downloadable release, so
# step the named variable back to the next-newest tag rather than guessing at a decremented
# version number that may never have existed. Fails if there is nothing older to fall to.
#
# Usage: find_prev_version_from_git_tags CLI_VERSION
find_prev_version_from_git_tags() {
  _variable_name="${1}"
  eval "_current_version=\${${_variable_name}}"

  load_gh_versions

  # shellcheck disable=SC2154 # _current_version is assigned by the eval above
  _previous_version="$(
    printf '%s\n' "${GH_VERSION_LIST}" |
      awk -v current="${_current_version}" 'found == 1 { print; found = 2 } $0 == current { found = 1 }'
  )"

  if [ -z "${_previous_version}" ]; then
    echo "(!) No github-cli version older than ${_current_version} is available to fall back to." >&2
    return 1
  fi

  eval "${_variable_name}=\${_previous_version}"
  echo "${_variable_name}=${_previous_version}"
}

# Determine the appropriate non-root user, setting USERNAME
# (mirrors other features' "automatic" behavior)
resolve_username() {
  USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"

  if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    for _candidate_user in vscode node codespace "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)"; do
      if [ -n "${_candidate_user}" ] && id -u "${_candidate_user}" >/dev/null 2>&1; then
        USERNAME="${_candidate_user}"
        break
      fi
    done
    if [ -z "${USERNAME}" ]; then
      USERNAME=root
    fi
  elif [ "${USERNAME}" = "none" ] || ! id -u "${USERNAME}" >/dev/null 2>&1; then
    USERNAME=root
  fi
}

# Install the extensions listed in EXTENSIONS as USERNAME
install_gh_extensions() {
  echo "Installing GitHub CLI extensions for ${USERNAME}..."

  if [ "${USERNAME}" = "root" ]; then
    EXTENSIONS="${EXTENSIONS}" bash "${EXTENSIONS_SCRIPT}"
    return
  fi

  # BusyBox `su` has no `--whitelist-environment`, so forward the GitHub auth tokens
  # explicitly - and only when they are set, so that an empty value is never mistaken for a
  # real one. The `-l`/`-c` short forms used here are accepted by util-linux `su` as well.
  _token_env=""
  for _token_var in GH_TOKEN GITHUB_TOKEN; do
    eval "_token_value=\${${_token_var}:-}"
    if [ -n "${_token_value}" ]; then
      _token_env="${_token_env}${_token_var}=$(shell_quote "${_token_value}") "
    fi
  done

  su -l "${USERNAME}" -c "${_token_env}EXTENSIONS=$(shell_quote "${EXTENSIONS}") USERNAME=$(shell_quote "${USERNAME}") INSTALL_EXTENSIONS=true bash $(shell_quote "${EXTENSIONS_SCRIPT}")"

  # Re-run as root solely to install the `gh extension list` shim, which has to live in a
  # system directory.
  INSTALL_EXTENSIONS=false bash "${EXTENSIONS_SCRIPT}"
}
