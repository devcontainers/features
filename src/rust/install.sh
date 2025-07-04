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
IFS=',' read -ra components <<< "${COMPONENTS:-rust-analyzer,rust-src,rustfmt,clippy}"

export CARGO_HOME="${CARGO_HOME:-"/usr/local/cargo"}"
export RUSTUP_HOME="${RUSTUP_HOME:-"/usr/local/rustup"}"
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
UPDATE_RC="${UPDATE_RC:-"true"}"
UPDATE_RUST="${UPDATE_RUST:-"false"}"

set -e

# Detect the Linux distribution and package manager
PKG_MANAGER=""

# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
. /etc/os-release
# Get an adjusted ID independent of distro variants
if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
    ADJUSTED_ID="debian"
elif [ "${ID}" = "alpine" ]; then
    ADJUSTED_ID="alpine"
elif [[ "${ID}" = "rhel" || "${ID}" = "fedora" || "${ID}" = "mariner" || "${ID_LIKE}" = *"rhel"* || "${ID_LIKE}" = *"fedora"* || "${ID_LIKE}" = *"mariner"* ]]; then
    ADJUSTED_ID="rhel"
    VERSION_CODENAME="${ID}${VERSION_ID}"
else
    echo "Linux distro ${ID} not supported."
    exit 1
fi

if [ "${ADJUSTED_ID}" = "rhel" ] && [ "${VERSION_CODENAME-}" = "centos7" ]; then
    # As of 1 July 2024, mirrorlist.centos.org no longer exists.
    # Update the repo files to reference vault.centos.org.
    sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo
    sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo
    sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo
fi


# Detect package manager
if command -v apt-get >/dev/null 2>&1; then
    PKG_MANAGER="apt"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
elif command -v yum >/dev/null 2>&1; then
    PKG_MANAGER="yum"
elif command -v microdnf >/dev/null 2>&1; then
    PKG_MANAGER="microdnf"
elif command -v tdnf >/dev/null 2>&1; then
    PKG_MANAGER="tdnf"
else
    echo "No supported package manager found. Supported: apt, dnf, yum, microdnf, tdnf"
    exit 1
fi

echo "Detected package manager: $PKG_MANAGER"

# Clean up based on package manager
clean_package_cache() {
    case "$PKG_MANAGER" in
        apt)
            if [ "$(ls -1 /var/lib/apt/lists/ 2>/dev/null | wc -l)" -gt 0 ]; then
                rm -rf /var/lib/apt/lists/*
            fi
            ;;
        dnf|yum|microdnf)
            if command -v dnf >/dev/null 2>&1; then
                dnf clean all
            elif command -v yum >/dev/null 2>&1; then
                yum clean all
            elif command -v microdnf >/dev/null 2>&1; then
                microdnf clean all
            fi
            ;;
        tdnf)
            tdnf clean all
            ;;
    esac
}

# Initial cleanup
clean_package_cache

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
        echo "Updating shell configuration files..."
        local bashrc_file="/etc/bash.bashrc"
        
        # Different distributions use different bashrc locations
        if [ ! -f "$bashrc_file" ]; then
            if [ -f "/etc/bashrc" ]; then
                bashrc_file="/etc/bashrc"
            elif [ -f "/etc/bash/bashrc" ]; then
                bashrc_file="/etc/bash/bashrc"
            fi
        fi
        
        if [ -f "$bashrc_file" ] && [[ "$(cat "$bashrc_file")" != *"$1"* ]]; then
            echo -e "$1" >> "$bashrc_file"
        fi
        
        if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/zsh/zshrc
        fi
    fi
}

# Package update functions
pkg_mgr_update() {
    case "$PKG_MANAGER" in
        apt)
            if [ "$(find /var/lib/apt/lists/* 2>/dev/null | wc -l)" = "0" ]; then
                echo "Running apt-get update..."
                apt-get update -y
            fi
            ;;
        dnf)
            dnf check-update || true
            ;;
        yum)
            yum check-update || true
            ;;
        microdnf)
            # microdnf doesn't have check-update
            true
            ;;
        tdnf)
            tdnf makecache || true
            ;;
    esac
}

# Check if package is installed
is_package_installed() {
    local package=$1
    case "$PKG_MANAGER" in
        apt)
            dpkg -s "$package" >/dev/null 2>&1
            ;;
        dnf|yum|microdnf|tdnf)
            rpm -q "$package" >/dev/null 2>&1
            ;;
    esac
}

# Unified package checking and installation function
check_packages() {
    local packages=("$@")
    local missing_packages=()

    # Check if curl-minimal is installed and swap it with curl
    if is_package_installed "curl-minimal"; then
        echo "curl-minimal is installed. Swapping it with curl..."
        case "$PKG_MANAGER" in
            dnf|yum|microdnf)
                ${PKG_MANAGER} swap curl-minimal curl -y
                ;;
            tdnf)
                tdnf remove -y curl-minimal
                tdnf install -y curl
                ;;
            *)
                echo "Package manager does not support swapping curl-minimal with curl. Please handle this manually."
                ;;
        esac
    fi

    # Map package names based on distribution
    for i in "${!packages[@]}"; do
        case "$PKG_MANAGER" in
            dnf|yum|microdnf|tdnf)
                case "${packages[$i]}" in
                    "libc6-dev") packages[$i]="glibc-devel" ;;
                    "python3-minimal") packages[$i]="python3" ;;
                    "libpython3.*") packages[$i]="python3-devel" ;;
                    "gnupg2") packages[$i]="gnupg" ;;
                esac
                ;;
        esac
    done

    # Check which packages are missing
    for package in "${packages[@]}"; do
        if [ -n "$package" ] && ! is_package_installed "$package"; then
            missing_packages+=("$package")
        fi
    done

    # Install missing packages
    if [ ${#missing_packages[@]} -gt 0 ]; then
        pkg_mgr_update
        case "$PKG_MANAGER" in
            apt)
                apt-get -y install --no-install-recommends "${missing_packages[@]}"
                ;;
            dnf)
                dnf install -y "${missing_packages[@]}"
                ;;
            yum)
                yum install -y "${missing_packages[@]}"
                ;;
            microdnf)
                microdnf install -y "${missing_packages[@]}"
                ;;
            tdnf)
                tdnf install -y "${missing_packages[@]}"
                ;;
        esac
    fi
}

export DEBIAN_FRONTEND=noninteractive

# Install curl, lldb, python3-minimal,libpython and rust dependencies if missing
echo "Installing required dependencies..."
check_packages curl ca-certificates gcc libc6-dev gnupg2 git

# Install optional dependencies (continue if they fail)
case "$PKG_MANAGER" in
    apt)
        check_packages lldb python3-minimal libpython3.? || true
        ;;
    dnf|yum|microdnf)
        check_packages lldb python3 python3-devel || true
        ;;
    tdnf)
        check_packages python3 python3-devel || true
        # LLDB might not be available in Photon/Mariner
        ;;
esac

# Get architecture
if command -v dpkg >/dev/null 2>&1; then
    architecture="$(dpkg --print-architecture)"
else
    architecture="$(uname -m)"
    # Convert common architectures to Debian equivalents
    case ${architecture} in
        x86_64)
            architecture="amd64"
            ;;
        aarch64)
            architecture="arm64"
            ;;
    esac
fi

download_architecture="${architecture}"
case ${download_architecture} in
 amd64|x86_64)
    download_architecture="x86_64"
    ;;
 arm64|aarch64)
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
# Install Rust components based on flag
echo "Installing Rust components..."
for component in "${components[@]}"; do
    # Trim leading and trailing whitespace
    component="${component#"${component%%[![:space:]]*}"}" && component="${component%"${component##*[![:space:]]}"}"
    if [ -n "${component}" ]; then
        echo "Installing Rust component: ${component}"
        if ! rustup component add "${component}" 2>&1; then
            echo "Warning: Failed to install component '${component}'. It may not be available for this toolchain." >&2
            exit 1
        fi
    fi
done

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
clean_package_cache

echo "Done!"
