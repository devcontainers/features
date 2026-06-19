#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/ruby.md
# Maintainer: The VS Code and Codespaces Teams

RUBY_VERSION="${VERSION:-"latest"}"

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
INSTALL_RUBY_TOOLS="${INSTALL_RUBY_TOOLS:-"true"}"

# Comma-separated list of ruby versions to be installed alongside RUBY_VERSION,
# but not set as default.
ADDITIONAL_VERSIONS="${ADDITIONALVERSIONS:-""}"

VERSION_MANAGER="${VERSIONMANAGER:-"none"}"

DEFAULT_GEMS="rake"

RUBY_BUILD_DIR="/usr/local/share/ruby-build"
RUBIES_DIR="/usr/local/rubies"
RUBY_GROUP="ruby"
RBENV_ROOT="/usr/local/share/rbenv"
RVM_PATH="/usr/local/rvm"
RVM_GPG_KEYS="409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB"

set -e

# Force apt to refresh its lists below by clearing them up front (no-op on non-apt systems).
rm -rf /var/lib/apt/lists/* 2>/dev/null || true

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

architecture="$(uname -m)"
if [ "${architecture}" != "amd64" ] && [ "${architecture}" != "x86_64" ] && [ "${architecture}" != "arm64" ] && [ "${architecture}" != "aarch64" ]; then
    echo "(!) Architecture $architecture unsupported"
    exit 1
fi

clone_or_update_repo() {
    local repo=$1 dest=$2
    if [ ! -d "${dest}" ]; then
        git clone --depth=1 \
            -c core.eol=lf \
            -c core.autocrlf=false \
            -c fsck.zeroPaddedFilemode=ignore \
            -c fetch.fsck.zeroPaddedFilemode=ignore \
            -c receive.fsck.zeroPaddedFilemode=ignore \
            "${repo}" "${dest}"
    else
        git -C "${dest}" fetch --depth=1 origin && \
            git -C "${dest}" reset --hard origin/HEAD || true
    fi
}

apply_group_perms() {
    local dir=$1
    chgrp -R "${RUBY_GROUP}" "${dir}" 2>/dev/null || true
    chmod -R g+rw "${dir}" 2>/dev/null || true
    find "${dir}" -type d -exec chmod g+s {} + 2>/dev/null || true
}

get_gpg_key_servers() {
    declare -A keyservers_curl_map=(
        ["hkp://keyserver.ubuntu.com"]="http://keyserver.ubuntu.com:11371"
        ["hkp://keyserver.ubuntu.com:80"]="http://keyserver.ubuntu.com"
        ["hkps://keys.openpgp.org"]="https://keys.openpgp.org"
        ["hkp://keyserver.pgp.com"]="http://keyserver.pgp.com:11371"
    )

    local curl_args=""
    local keyserver_reachable=false

    if [ -n "${KEYSERVER_PROXY:-}" ]; then
        curl_args="--proxy ${KEYSERVER_PROXY}"
    fi

    for keyserver in "${!keyservers_curl_map[@]}"; do
        local keyserver_curl_url="${keyservers_curl_map[${keyserver}]}"
        if curl -s ${curl_args} --max-time 5 "${keyserver_curl_url}" > /dev/null; then
            echo "keyserver ${keyserver}"
            keyserver_reachable=true
        else
            echo "(*) Keyserver ${keyserver} is not reachable." >&2
        fi
    done

    if ! $keyserver_reachable; then
        echo "(!) No keyserver is reachable." >&2
        exit 1
    fi
}

receive_gpg_keys() {
    local keys=${!1}
    local keyring_args=""
    if [ -n "${2:-}" ]; then
        keyring_args="--no-default-keyring --keyring \"$2\""
    fi

    export GNUPGHOME="/tmp/tmp-gnupg"
    mkdir -p "${GNUPGHOME}"
    chmod 700 "${GNUPGHOME}"
    echo -e "disable-ipv6\n$(get_gpg_key_servers)" > "${GNUPGHOME}/dirmngr.conf"

    local retry_count=0
    local gpg_ok="false"
    set +e
    until [ "${gpg_ok}" = "true" ] || [ "${retry_count}" -eq "5" ]; do
        echo "(*) Downloading GPG key..."
        # shellcheck disable=SC2086
        ( echo "${keys}" | xargs -n 1 gpg -q ${keyring_args} --recv-keys) 2>&1 && gpg_ok="true"
        if [ "${gpg_ok}" != "true" ]; then
            echo "(*) Failed getting key, retrying in 10s..."
            (( retry_count++ ))
            sleep 10s
        fi
    done
    set -e
    if [ "${gpg_ok}" = "false" ]; then
        echo "(!) Failed to get gpg key."
        exit 1
    fi
}

default_ruby_version() {
    [ -L "${RUBIES_DIR}/current" ] && basename "$(readlink "${RUBIES_DIR}/current")"
}

install_build_deps() {
    if command -v apt-get > /dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        # libgdbm-dev pulls the appropriate libgdbm runtime, so no version-specific package is needed.
        apt-get -y install --no-install-recommends \
            curl ca-certificates git autoconf bison patch build-essential \
            libssl-dev libyaml-dev libreadline-dev zlib1g-dev libgmp-dev \
            libncurses-dev libffi-dev libgdbm-dev libdb-dev uuid-dev
    elif command -v dnf > /dev/null 2>&1 || command -v yum > /dev/null 2>&1; then
        local pm
        pm="$(command -v dnf || command -v yum)"
        "${pm}" install -y \
            curl ca-certificates git gcc make patch autoconf bison \
            openssl-devel libyaml-devel zlib-devel libffi-devel \
            readline-devel ncurses-devel gdbm-devel
    elif command -v apk > /dev/null 2>&1; then
        apk add --no-cache \
            bash curl ca-certificates git build-base linux-headers \
            autoconf bison patch openssl-dev yaml-dev zlib-dev \
            readline-dev ncurses-dev libffi-dev gdbm-dev
    elif command -v zypper > /dev/null 2>&1; then
        zypper --non-interactive install --no-recommends \
            curl ca-certificates git gcc-c++ make patch \
            autoconf automake libtool bison \
            libopenssl-devel libyaml-devel zlib-devel libffi-devel \
            readline-devel ncurses-devel gdbm-devel
    elif command -v pacman > /dev/null 2>&1; then
        pacman -Sy --noconfirm --needed \
            curl ca-certificates git base-devel autoconf bison \
            openssl libyaml zlib libffi readline ncurses gdbm
    else
        echo "(!) No supported package manager found. Install Ruby build dependencies manually."
        exit 1
    fi
}

install_ruby_build() {
    clone_or_update_repo "https://github.com/rbenv/ruby-build.git" "${RUBY_BUILD_DIR}"
    ln -sf "${RUBY_BUILD_DIR}/bin/ruby-build" /usr/local/bin/ruby-build
}

resolve_ruby_version() {
    local requested=$1
    local definitions_dir="${RUBY_BUILD_DIR}/share/ruby-build"
    local stable_versions
    stable_versions="$(ls "${definitions_dir}" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V)"

    if [ -z "${stable_versions}" ]; then
        echo "(!) ruby-build has no version definitions at ${definitions_dir}." >&2
        exit 1
    fi

    case "${requested}" in
        latest|current|lts)
            echo "${stable_versions}" | tail -n 1
            ;;
        *)
            if echo "${stable_versions}" | grep -qx "${requested}"; then
                echo "${requested}"
                return
            fi
            # Resolve a partial X.Y to the highest matching X.Y.Z.
            local match
            match="$(echo "${stable_versions}" | grep -E "^${requested//./\\.}\\.[0-9]+$" | sort -V | tail -n 1)"
            if [ -n "${match}" ]; then
                echo "${match}"
                return
            fi
            echo "(!) Ruby version '${requested}' is not known to ruby-build." >&2
            exit 1
            ;;
    esac
}

install_ruby_version() {
    local requested=$1
    local set_default=$2
    local resolved
    resolved="$(resolve_ruby_version "${requested}")"
    local prefix="${RUBIES_DIR}/${resolved}"

    if [ -x "${prefix}/bin/ruby" ]; then
        echo "(!) Ruby ${resolved} already installed at ${prefix}. Skipping..."
    elif [ "${VERSION_MANAGER}" = "rbenv" ] && [ -x "${RBENV_ROOT}/bin/rbenv" ]; then
        echo "Installing Ruby ${resolved} via rbenv..."
        mkdir -p "${RUBIES_DIR}"
        LANG="${LANG:-C.UTF-8}" RBENV_ROOT="${RBENV_ROOT}" \
            "${RBENV_ROOT}/bin/rbenv" install --skip-existing "${resolved}"
        # Mirror into RUBIES_DIR so the rest of the script uses a consistent path.
        ln -sfn "${RBENV_ROOT}/versions/${resolved}" "${prefix}"
    elif [ "${VERSION_MANAGER}" = "rvm" ] && [ -s "${RVM_PATH}/scripts/rvm" ]; then
        echo "Installing Ruby ${resolved} via rvm..."
        mkdir -p "${RUBIES_DIR}"
        # shellcheck disable=SC1091
        source "${RVM_PATH}/scripts/rvm"
        LANG="${LANG:-C.UTF-8}" rvm install "${resolved}"
        local rvm_ruby="${RVM_PATH}/rubies/ruby-${resolved}"
        if [ -d "${rvm_ruby}" ]; then
            ln -sfn "${rvm_ruby}" "${prefix}"
        fi
    else
        mkdir -p "${RUBIES_DIR}"
        echo "Installing Ruby ${resolved} via ruby-build..."
        # Ensure a UTF-8 locale so that rdoc (and other tools bundled with Ruby)
        # can process non-ASCII bytes during `make install`, even on minimal
        # base images that ship with no LANG set (e.g. Debian 11 bullseye).
        LANG="${LANG:-C.UTF-8}" ruby-build "${resolved}" "${prefix}"
    fi

    if [ "${set_default}" = "true" ]; then
        ln -sfn "${prefix}" "${RUBIES_DIR}/current"
    fi
}

# Called before ruby versions are installed so that install_ruby_version()
# can delegate to 'rbenv install'.
install_rbenv() {
    echo "Installing rbenv..."
    clone_or_update_repo "https://github.com/rbenv/rbenv.git" "${RBENV_ROOT}"

    ln -sf "${RBENV_ROOT}/bin/rbenv" /usr/local/bin/rbenv

    # Wire the already-installed ruby-build as an rbenv plugin so that
    # 'rbenv install' works out of the box.
    mkdir -p "${RBENV_ROOT}/plugins"
    if [ ! -e "${RBENV_ROOT}/plugins/ruby-build" ]; then
        ln -sfn "${RUBY_BUILD_DIR}" "${RBENV_ROOT}/plugins/ruby-build"
    fi
    mkdir -p "${RBENV_ROOT}/versions"
    echo "rbenv ready at ${RBENV_ROOT}."
}

# Called after ruby versions are installed.
finalize_rbenv() {
    # When rubies were installed via ruby-build (not 'rbenv install'), symlink them
    # into rbenv's versions directory so 'rbenv versions' shows them.
    # Skip entries that already point into RBENV_ROOT to avoid circular symlinks.
    for ruby_dir in "${RUBIES_DIR}"/[0-9]*/; do
        [ -d "${ruby_dir}" ] || continue
        local ver
        ver="$(basename "${ruby_dir%/}")"
        local real_target
        real_target="$(readlink -f "${ruby_dir%/}" 2>/dev/null || true)"
        if [ "${real_target}" = "${RBENV_ROOT}/versions/${ver}" ]; then
            continue
        fi
        ln -sfn "${ruby_dir%/}" "${RBENV_ROOT}/versions/${ver}"
    done

    # Set the rbenv global version to match the ruby-build default.
    local default_ver
    default_ver="$(default_ruby_version)"
    if [ -n "${default_ver}" ]; then
        echo "${default_ver}" > "${RBENV_ROOT}/version"
    fi

    apply_group_perms "${RBENV_ROOT}"

    # Profile script for login shells (non-login shells rely on containerEnv
    # which already prepends RBENV_ROOT/shims and RBENV_ROOT/bin).
    cat > /etc/profile.d/rbenv.sh << 'RBENV_PROFILE'
export RBENV_ROOT=/usr/local/share/rbenv
export PATH="${RBENV_ROOT}/bin:${RBENV_ROOT}/shims:${PATH}"
eval "$(rbenv init - --no-rehash)" 2>/dev/null || true
RBENV_PROFILE
    chmod +x /etc/profile.d/rbenv.sh

    RBENV_ROOT="${RBENV_ROOT}" "${RBENV_ROOT}/bin/rbenv" rehash 2>/dev/null || true
    echo "rbenv configured."
}

# Called before ruby versions are installed so that install_ruby_version()
# can delegate to 'rvm install'.
install_rvm() {
    echo "Installing rvm..."

    receive_gpg_keys RVM_GPG_KEYS

    curl -sSL https://get.rvm.io | bash -s stable --path "${RVM_PATH}"

    # rvm is a shell function, so we must source it before calling 'rvm' below.
    # shellcheck disable=SC1091
    if [ -s "${RVM_PATH}/scripts/rvm" ]; then
        source "${RVM_PATH}/scripts/rvm"
    fi
    echo "rvm ready at ${RVM_PATH}."
}

finalize_rvm() {
    # shellcheck disable=SC1091
    [ -s "${RVM_PATH}/scripts/rvm" ] && source "${RVM_PATH}/scripts/rvm" || true

    # When rubies were installed via ruby-build (not 'rvm install'), mount them
    # into rvm so 'rvm list' shows them.  Skip entries that already live under
    # RVM_PATH to avoid double-mounting.
    if [ -d "${RUBIES_DIR}" ]; then
        for ruby_dir in "${RUBIES_DIR}"/[0-9]*/; do
            [ -d "${ruby_dir}" ] || continue
            local ver
            ver="$(basename "${ruby_dir%/}")"
            local real_target
            real_target="$(readlink -f "${ruby_dir%/}" 2>/dev/null || true)"
            if [[ "${real_target}" == "${RVM_PATH}/rubies/"* ]]; then
                continue
            fi
            rvm mount "${ruby_dir%/}" -n "${ver}" 2>/dev/null || true
        done
    fi

    # Set the rvm default to match the ruby-build default.
    local default_ver
    default_ver="$(default_ruby_version)"
    if [ -n "${default_ver}" ]; then
        local real_current
        real_current="$(readlink -f "${RUBIES_DIR}/current" 2>/dev/null || true)"
        if [[ "${real_current}" == "${RVM_PATH}/rubies/"* ]]; then
            # Installed via 'rvm install': use the version name directly.
            rvm use "${default_ver}" --default 2>/dev/null || true
        else
            # Installed via ruby-build and mounted: use the 'ext-' prefix.
            rvm use "ext-${default_ver}" --default 2>/dev/null || true
        fi
    fi

    echo "source ${RVM_PATH}/scripts/rvm" > /etc/profile.d/rvm.sh
    chmod +x /etc/profile.d/rvm.sh

    if [ "${USERNAME}" != "root" ] && id -u "${USERNAME}" > /dev/null 2>&1; then
        usermod -aG rvm "${USERNAME}" 2>/dev/null || true
    fi
    echo "rvm configured."
}

install_build_deps
install_ruby_build

# Create a shared "ruby" group so the configured user can write under the rubies tree.
if ! getent group "${RUBY_GROUP}" > /dev/null 2>&1; then
    groupadd -r "${RUBY_GROUP}" 2>/dev/null || addgroup -S "${RUBY_GROUP}" 2>/dev/null || true
fi
mkdir -p "${RUBIES_DIR}"
chgrp "${RUBY_GROUP}" "${RUBIES_DIR}" 2>/dev/null || true
chmod 2775 "${RUBIES_DIR}" 2>/dev/null || true

# Set up the version manager BEFORE installing Ruby versions so that
# install_ruby_version() can delegate to it when requested.
if [ "${VERSION_MANAGER}" = "rbenv" ]; then
    install_rbenv
elif [ "${VERSION_MANAGER}" = "rvm" ]; then
    install_rvm
fi

if [ "${RUBY_VERSION}" != "none" ]; then
    install_ruby_version "${RUBY_VERSION}" "true"
fi

if [ ! -z "${ADDITIONAL_VERSIONS}" ]; then
    OLDIFS=$IFS
    IFS=","
        read -a additional_versions <<< "$ADDITIONAL_VERSIONS"
        for version in "${additional_versions[@]}"; do
            install_ruby_version "${version}" "false"
        done
    IFS=$OLDIFS
fi

# Expose the default Ruby on the PATH for all login shells.
echo 'export PATH="/usr/local/rubies/current/bin:${PATH}"' > /etc/profile.d/ruby.sh
chmod +x /etc/profile.d/ruby.sh

if [ "${RUBY_VERSION}" != "none" ] && [ "${INSTALL_RUBY_TOOLS}" = "true" ]; then
    "${RUBIES_DIR}/current/bin/gem" install --no-document ${DEFAULT_GEMS}
fi

# Make sure the configured user can install gems against the shared rubies tree.
if [ "${USERNAME}" != "root" ] && id -u "${USERNAME}" > /dev/null 2>&1; then
    if command -v usermod > /dev/null 2>&1; then
        usermod -aG "${RUBY_GROUP}" "${USERNAME}" || true
    elif command -v addgroup > /dev/null 2>&1; then
        addgroup "${USERNAME}" "${RUBY_GROUP}" || true
    fi
fi

apply_group_perms "${RUBIES_DIR}"

if command -v apt-get > /dev/null 2>&1; then
    rm -rf /var/lib/apt/lists/*
fi

# Finalize the version manager now that all ruby versions are installed.
if [ "${VERSION_MANAGER}" = "rbenv" ]; then
    finalize_rbenv
elif [ "${VERSION_MANAGER}" = "rvm" ]; then
    finalize_rvm
fi

echo "Done!"
