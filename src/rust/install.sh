#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/rust.md
# Maintainer: The VS Code and Codespaces Teams

RUST_VERSION="${VERSION:-"latest"}"
RUSTUP_PROFILE="${PROFILE:-"minimal"}"
RUSTUP_TARGETS="${TARGETS:-""}"

export CARGO_HOME="${CARGO_HOME:-"/usr/local/cargo"}"
export RUSTUP_HOME="${RUSTUP_HOME:-"/usr/local/rustup"}"
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
UPDATE_RC="${UPDATE_RC:-"true"}"
UPDATE_RUST="${UPDATE_RUST:-"false"}"

set -e

# Clean up
if [ "$(ls -1 /var/lib/apt/lists/ | wc -l)" -gt -1 ]; then
    rm -rf /var/lib/apt/lists/*
fi

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "${CURRENT_USER}" > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u "${USERNAME}" > /dev/null 2>&1; then
    USERNAME=root
fi

# Figure out correct version of a three part version number is not passed
find_version_from_git_tags() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    local prefix=${3:-"tags/v"}
    local separator=${4:-"."}
    local last_part_optional=${5:-"false"}
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator=${separator//./\\.}
        local last_part
        if [ "${last_part_optional}" = "true" ]; then
            last_part="(${escaped_separator}[0-9]+)?"
        else
            last_part="${escaped_separator}[0-9]+"
        fi
        local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${last_part}$"
        local version_list="$(git ls-remote --tags "${repository}" | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            declare -g ${variable_name}="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            declare -g ${variable_name}="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
            set -e
        fi
    fi
    if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" > /dev/null 2>&1; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        exit 1
    fi
    echo "${variable_name}=${!variable_name}"
}

check_nightly_version_formatting() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi

    local version_date=$(echo ${requested_version} | sed -e "s/^nightly-//")


    if ! date -d "${version_date}" &>/dev/null; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nNightly version should be in the format nightly-YYYY-MM-DD" >&2
        exit 1
    fi

    if [ "$(date -d "${version_date}" +%s)" -ge "$(date +%s)" ]; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nNightly version should not exceed current date" >&2
        exit 1
    fi
}

updaterc() {
    if [ "${UPDATE_RC}" = "true" ]; then
        echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."
        if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/bash.bashrc
        fi
        if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/zsh/zshrc
        fi
    fi
}

apt_get_update()
{
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

export DEBIAN_FRONTEND=noninteractive

# Install curl, lldb, python3-minimal,libpython and rust dependencies if missing
if ! dpkg -s curl ca-certificates gnupg2 lldb python3-minimal gcc libc6-dev > /dev/null 2>&1; then
    apt_get_update
    apt-get -y install --no-install-recommends curl ca-certificates gcc libc6-dev
    apt-get -y install lldb python3-minimal libpython3.?
fi

architecture="$(dpkg --print-architecture)"
download_architecture="${architecture}"
case ${download_architecture} in
 amd64)
    download_architecture="x86_64"
    ;;
 arm64)
    download_architecture="aarch64"
    ;;
 *) echo "(!) Architecture ${architecture} not supported."
    exit 1
    ;;
esac

# Install Rust
umask 0002
if ! grep -e "^rustlang:" /etc/group > /dev/null 2>&1; then
    groupadd -r rustlang
fi
usermod -a -G rustlang "${USERNAME}"
mkdir -p "${CARGO_HOME}" "${RUSTUP_HOME}"
chown "${USERNAME}:rustlang" "${RUSTUP_HOME}" "${CARGO_HOME}"
chmod g+r+w+s "${RUSTUP_HOME}" "${CARGO_HOME}"

if [ "${RUST_VERSION}" = "none" ] || type rustup > /dev/null 2>&1; then
    echo "Rust already installed. Skipping..."
else
    if [ "${RUST_VERSION}" != "latest" ] && [ "${RUST_VERSION}" != "lts" ] && [ "${RUST_VERSION}" != "stable" ]; then
        # Find version using soft match
        if ! type git > /dev/null 2>&1; then
            check_packages git
        fi

        is_nightly=0
        echo "${RUST_VERSION}" | grep -q "nightly" || is_nightly=$?
        if [ $is_nightly = 0 ]; then
            check_nightly_version_formatting RUST_VERSION
        else
            find_version_from_git_tags RUST_VERSION "https://github.com/rust-lang/rust" "tags/"
        fi
        default_toolchain_arg="--default-toolchain ${RUST_VERSION}"
    fi
    echo "Installing Rust..."
    # Download and verify rustup sha
    mkdir -p /tmp/rustup/target/${download_architecture}-unknown-linux-gnu/release/
    curl -sSL --proto '=https' --tlsv1.2 "https://static.rust-lang.org/rustup/dist/${download_architecture}-unknown-linux-gnu/rustup-init" -o /tmp/rustup/target/${download_architecture}-unknown-linux-gnu/release/rustup-init
    curl -sSL --proto '=https' --tlsv1.2 "https://static.rust-lang.org/rustup/dist/${download_architecture}-unknown-linux-gnu/rustup-init.sha256" -o /tmp/rustup/rustup-init.sha256
    cd /tmp/rustup
    cp /tmp/rustup/target/${download_architecture}-unknown-linux-gnu/release/rustup-init  /tmp/rustup/rustup-init
    sha256sum -c rustup-init.sha256
    chmod +x target/${download_architecture}-unknown-linux-gnu/release/rustup-init
    target/${download_architecture}-unknown-linux-gnu/release/rustup-init -y --no-modify-path --profile "${RUSTUP_PROFILE}" ${default_toolchain_arg}
    cd ~
    rm -rf /tmp/rustup
fi

export PATH=${CARGO_HOME}/bin:${PATH}
if [ "${UPDATE_RUST}" = "true" ]; then
    echo "Updating Rust..."
    rustup update 2>&1
fi
echo "Installing common Rust dependencies..."
rustup component add rls rust-analysis rust-src rustfmt clippy 2>&1

if [ -n "${RUSTUP_TARGETS}" ]; then
    IFS=',' read -ra targets <<< "${RUSTUP_TARGETS}"
    for target in "${targets[@]}"; do
        echo "Installing additional Rust target $target"
        rustup target add "$target" 2>&1
    done
fi

# Add CARGO_HOME, RUSTUP_HOME and bin directory into bashrc/zshrc files (unless disabled)
updaterc "$(cat << EOF
export RUSTUP_HOME="${RUSTUP_HOME}"
export CARGO_HOME="${CARGO_HOME}"
if [[ "\${PATH}" != *"\${CARGO_HOME}/bin"* ]]; then export PATH="\${CARGO_HOME}/bin:\${PATH}"; fi
EOF
)"

# Make files writable for rustlang group
chmod -R g+r+w "${RUSTUP_HOME}" "${CARGO_HOME}"

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"

