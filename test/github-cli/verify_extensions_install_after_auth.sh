#!/usr/bin/env bash

set -euo pipefail

TEST_ROOT=/tmp/github-cli-extension-auth-test
BIN_DIR="${TEST_ROOT}/bin"
HOME_DIR="${TEST_ROOT}/home"
LOG_FILE="${TEST_ROOT}/log"
STATE_FILE="${TEST_ROOT}/state"
TOKEN_FILE="${TEST_ROOT}/token"
INSTALLED_FILE="${TEST_ROOT}/installed"

resolve_target_username() {
    local current_user
    local possible_users

    possible_users=("vscode" "node" "codespace" "ubuntu" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for current_user in "${possible_users[@]}"; do
        if [ -n "${current_user}" ] && id -u "${current_user}" > /dev/null 2>&1; then
            echo "${current_user}"
            return
        fi
    done

    echo root
}

rm -rf "${TEST_ROOT}"
mkdir -p "${BIN_DIR}" "${HOME_DIR}"

cat > "${BIN_DIR}/gh" <<'EOF'
#!/bin/bash
set -euo pipefail

TEST_ROOT=/tmp/github-cli-extension-auth-test
LOG_FILE="${TEST_ROOT}/log"
STATE_FILE="${TEST_ROOT}/state"
TOKEN_FILE="${TEST_ROOT}/token"
INSTALLED_FILE="${TEST_ROOT}/installed"

command_name="${1:-}"
subcommand_name="${2:-}"

case "${command_name}:${subcommand_name}" in
    auth:status)
        [ -f "${STATE_FILE}" ]
        ;;
    auth:login)
        if [ "${3:-}" = "--with-token" ]; then
            cat > "${TOKEN_FILE}"
            echo with-token >> "${LOG_FILE}"
            touch "${STATE_FILE}"
            exit 0
        fi

        echo interactive >> "${LOG_FILE}"
        touch "${STATE_FILE}"
        ;;
    extension:list)
        if [ -f "${INSTALLED_FILE}" ]; then
            while IFS= read -r extension; do
                printf '%s\t%s\n' "${extension}" "stub"
            done < "${INSTALLED_FILE}"
        fi
        ;;
    extension:install)
        extension="${3:-}"
        [ -f "${STATE_FILE}" ]
        echo "extension-install:${extension}" >> "${LOG_FILE}"
        echo "${extension}" >> "${INSTALLED_FILE}"
        mkdir -p "${HOME}/.local/share/gh/extensions/${extension##*/}"
        ;;
    *)
        exit 1
        ;;
esac
EOF

cat > "${BIN_DIR}/git" <<'EOF'
#!/bin/bash
echo git-called >> /tmp/github-cli-extension-auth-test/log
exit 99
EOF

chmod +x "${BIN_DIR}/gh" "${BIN_DIR}/git"

target_username="$(resolve_target_username)"
if [ "${target_username}" != "root" ]; then
    chown -R "${target_username}:${target_username}" "${TEST_ROOT}"
    su - "${target_username}" -c "PATH=${BIN_DIR}:\$PATH HOME=${HOME_DIR} GH_TOKEN=test-token /usr/local/share/github-cli-auth-on-setup.sh"
else
    PATH="${BIN_DIR}:${PATH}" \
    HOME="${HOME_DIR}" \
    GH_TOKEN=test-token \
    /usr/local/share/github-cli-auth-on-setup.sh
fi

grep -Fxq 'with-token' "${LOG_FILE}"
grep -Fxq 'extension-install:dlvhdr/gh-dash' "${LOG_FILE}"
grep -Fxq 'extension-install:github/gh-copilot' "${LOG_FILE}"
grep -Fxq 'test-token' "${TOKEN_FILE}"
test -d "${HOME_DIR}/.local/share/gh/extensions/gh-dash"
test -d "${HOME_DIR}/.local/share/gh/extensions/gh-copilot"
test -f "${HOME_DIR}/.config/vscode-dev-containers/github-cli-auth-already-ran"
if grep -Fxq 'git-called' "${LOG_FILE}"; then
    echo "git fallback was used unexpectedly" >&2
    exit 1
fi