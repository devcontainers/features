#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

validation_script='is_true() {
    case "$(printf "%s" "$1" | tr "[:upper:]" "[:lower:]")" in
        true|1|yes)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

if [ -n "${EXTENSIONS:-}" ] && ! is_true "${AUTHONSETUP:-false}" && ! is_true "${INSTALLEXTENSIONSFROMGIT:-false}"; then
    echo "(!) Unsupported extensions configuration. When 'extensions' is set, enable 'authOnSetup' to install after authentication or set 'installExtensionsFromGit' to true to clone extensions during feature setup." >&2
    exit 1
fi'

if [ -f "${repo_root}/src/github-cli/install.sh" ]; then
    validation_script='source "'"${repo_root}"'"/src/github-cli/install.sh; validate_configuration'
fi

set +e
output="$({
    EXTENSIONS="dlvhdr/gh-dash" \
    INSTALLEXTENSIONSFROMGIT=false \
    AUTHONSETUP=false \
    bash -lc "${validation_script}"
} 2>&1)"
status=$?
set -e

if [ "${status}" -eq 0 ]; then
    echo "Expected unsupported extensions configuration to fail." >&2
    exit 1
fi

printf '%s' "${output}" | grep -Fq "Unsupported extensions configuration."