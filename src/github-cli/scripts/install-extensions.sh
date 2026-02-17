#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

set -e

EXTENSIONS=${EXTENSIONS:-""}
INSTALL_EXTENSIONS=${INSTALL_EXTENSIONS:-"true"}

trim() {
    local value="$1"
    value="${value#${value%%[![:space:]]*}}"
    value="${value%${value##*[![:space:]]}}"
    echo "${value}"
}

install_extension() {
    local extension="$1"
    local extensions_root
    local repo_name

    extensions_root="${XDG_DATA_HOME:-"${HOME}/.local/share"}/gh/extensions"
    repo_name="${extension##*/}"

    mkdir -p "${extensions_root}"
    if [ ! -d "${extensions_root}/${repo_name}" ]; then
        git clone --depth 1 "https://github.com/${extension}.git" "${extensions_root}/${repo_name}"
    fi
}

ensure_gh_extension_list_wrapper() {
    if [ "$(id -u)" -ne 0 ]; then
        return
    fi

    if gh extension list >/dev/null 2>&1; then
        return
    fi

    cat > /usr/local/bin/gh <<'EOF'
#!/usr/bin/env bash
set -e

REAL_GH=/usr/bin/gh

if [ "$#" -ge 2 ]; then
    cmd="$1"
    sub="$2"
    if { [ "$cmd" = "extension" ] || [ "$cmd" = "extensions" ] || [ "$cmd" = "ext" ]; } && { [ "$sub" = "list" ] || [ "$sub" = "ls" ]; }; then
        extensions_root="${XDG_DATA_HOME:-"$HOME/.local/share"}/gh/extensions"
        if [ -d "$extensions_root" ]; then
            shopt -s nullglob
            for d in "$extensions_root"/*; do
                [ -d "$d" ] || continue
                url=""
                if command -v git >/dev/null 2>&1 && [ -d "$d/.git" ]; then
                    url="$(git -C "$d" config --get remote.origin.url 2>/dev/null || true)"
                fi
                if [ -n "$url" ]; then
                    url="${url%.git}"
                    url="${url#https://github.com/}"
                    url="${url#http://github.com/}"
                    url="${url#ssh://git@github.com/}"
                    url="${url#git@github.com:}"
                    echo "$url"
                fi
            done
        fi
        exit 0
    fi
fi

exec "$REAL_GH" "$@"
EOF
    chmod +x /usr/local/bin/gh
}

if [ "${INSTALL_EXTENSIONS}" = "true" ]; then
    if [ -z "${EXTENSIONS}" ]; then
        exit 0
    fi

    echo "Installing GitHub CLI extensions: ${EXTENSIONS}"
    IFS=',' read -r -a extension_list <<< "${EXTENSIONS}"
    for extension in "${extension_list[@]}"; do
        extension="$(trim "${extension}")"
        if [ -z "${extension}" ]; then
            continue
        fi

        install_extension "${extension}"
    done
fi

ensure_gh_extension_list_wrapper
