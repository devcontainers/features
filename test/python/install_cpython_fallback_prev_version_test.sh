#!/bin/bash

# Optional: Import test library
source dev-container-features-test-lib

check "Python version as installed by Feature" bash -c "python3 -V"

PYTHON_INSTALL_PATH="/usr/local/python"
OPTIMIZE_BUILD_FROM_SOURCE="false"
OVERRIDE_DEFAULT_VERSION="true"
ENABLESHARED="false"
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi
# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
. /etc/os-release
# Get an adjusted ID independent of distro variants
MAJOR_VERSION_ID=$(echo ${VERSION_ID} | cut -d . -f 1)
if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
    ADJUSTED_ID="debian"
elif [[ "${ID}" = "rhel" || "${ID}" = "fedora" || "${ID}" = "mariner" || "${ID_LIKE}" = *"rhel"* || "${ID_LIKE}" = *"fedora"* || "${ID_LIKE}" = *"mariner"* ]]; then
    ADJUSTED_ID="rhel"
    if [[ "${ID}" = "rhel" ]] || [[ "${ID}" = *"alma"* ]] || [[ "${ID}" = *"rocky"* ]]; then
        VERSION_CODENAME="rhel${MAJOR_VERSION_ID}"
    else
        VERSION_CODENAME="${ID}${MAJOR_VERSION_ID}"
    fi
else
    echo "Linux distro ${ID} not supported."
    exit 1
fi

# Setup INSTALL_CMD & PKG_MGR_CMD
if type apt-get > /dev/null 2>&1; then
    PKG_MGR_CMD=apt-get
    INSTALL_CMD="${PKG_MGR_CMD} -y install --no-install-recommends"
elif type microdnf > /dev/null 2>&1; then
    PKG_MGR_CMD=microdnf
    INSTALL_CMD="${PKG_MGR_CMD} ${INSTALL_CMD_ADDL_REPOS} -y install --refresh --best --nodocs --noplugins --setopt=install_weak_deps=0"
elif type dnf > /dev/null 2>&1; then
    PKG_MGR_CMD=dnf
    INSTALL_CMD="${PKG_MGR_CMD} ${INSTALL_CMD_ADDL_REPOS} -y install --refresh --best --nodocs --noplugins --setopt=install_weak_deps=0"
else
    PKG_MGR_CMD=yum
    INSTALL_CMD="${PKG_MGR_CMD} ${INSTALL_CMD_ADDL_REPOS} -y install --noplugins --setopt=install_weak_deps=0"
fi

pkg_mgr_update() {
    case $ADJUSTED_ID in
        debian)
            if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
                echo "Running apt-get update..."
                ${PKG_MGR_CMD} update -y
            fi
            ;;
        rhel)
            if [ ${PKG_MGR_CMD} = "microdnf" ]; then
                if [ "$(ls /var/cache/yum/* 2>/dev/null | wc -l)" = 0 ]; then
                    echo "Running ${PKG_MGR_CMD} makecache ..."
                    ${PKG_MGR_CMD} makecache
                fi
            else
                if [ "$(ls /var/cache/${PKG_MGR_CMD}/* 2>/dev/null | wc -l)" = 0 ]; then
                    echo "Running ${PKG_MGR_CMD} check-update ..."
                    set +e
                    ${PKG_MGR_CMD} check-update
                    rc=$?
                    if [ $rc != 0 ] && [ $rc != 100 ]; then
                        exit 1
                    fi
                    set -e
                fi
            fi
            ;;
    esac
}

check_packages() {
    case ${ADJUSTED_ID} in
        debian)
            if ! dpkg -s "$@" > /dev/null 2>&1; then
                pkg_mgr_update
                ${INSTALL_CMD} "$@"
            fi
            ;;
        rhel)
            if ! rpm -q "$@" > /dev/null 2>&1; then
                pkg_mgr_update
                ${INSTALL_CMD} "$@"
            fi
            ;;
    esac
}

# Get the list of GPG key servers that are reachable
get_gpg_key_servers() {
    declare -A keyservers_curl_map=(
        ["hkp://keyserver.ubuntu.com"]="http://keyserver.ubuntu.com:11371"
        ["hkp://keyserver.ubuntu.com:80"]="http://keyserver.ubuntu.com"
        ["hkps://keys.openpgp.org"]="https://keys.openpgp.org"
        ["hkp://keyserver.pgp.com"]="http://keyserver.pgp.com:11371"
    )

    local curl_args=""
    local keyserver_reachable=false  # Flag to indicate if any keyserver is reachable

    if [ ! -z "${KEYSERVER_PROXY}" ]; then
        curl_args="--proxy ${KEYSERVER_PROXY}"
    fi

    for keyserver in "${!keyservers_curl_map[@]}"; do
        local keyserver_curl_url="${keyservers_curl_map[${keyserver}]}"
        if curl -s ${curl_args} --max-time 5 ${keyserver_curl_url} > /dev/null; then
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

# Import the specified key in a variable name passed in as 
receive_gpg_keys() {
    local keys=${!1}
    local keyring_args=""
    local gpg_cmd="gpg"
    if [ ! -z "$2" ]; then
        mkdir -p "$(dirname \"$2\")"
        keyring_args="--no-default-keyring --keyring $2"
    fi
    if [ ! -z "${KEYSERVER_PROXY}" ]; then
        keyring_args="${keyring_args} --keyserver-options http-proxy=${KEYSERVER_PROXY}"
    fi

    # Install curl
    if ! type curl > /dev/null 2>&1; then
        check_packages curl
    fi

    # Use a temporary location for gpg keys to avoid polluting image
    export GNUPGHOME="/tmp/tmp-gnupg"
    mkdir -p ${GNUPGHOME}
    chmod 700 ${GNUPGHOME}
    echo -e "disable-ipv6\n$(get_gpg_key_servers)" > ${GNUPGHOME}/dirmngr.conf
    # GPG key download sometimes fails for some reason and retrying fixes it.
    local retry_count=0
    local gpg_ok="false"
    set +e
    until [ "${gpg_ok}" = "true" ] || [ "${retry_count}" -eq "5" ]; 
    do
        echo "(*) Downloading GPG key..."
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
# RHEL7/CentOS7 has an older gpg that does not have dirmngr
# Iterate through keyservers until we have all the keys downloaded
receive_gpg_keys_centos7() {
    local keys=${!1}
    local keyring_args=""
    local gpg_cmd="gpg"
    if [ ! -z "$2" ]; then
        mkdir -p "$(dirname \"$2\")"
        keyring_args="--no-default-keyring --keyring $2"
    fi
    if [ ! -z "${KEYSERVER_PROXY}" ]; then
        keyring_args="${keyring_args} --keyserver-options http-proxy=${KEYSERVER_PROXY}"
    fi

    # Install curl
    if ! type curl > /dev/null 2>&1; then
        check_packages curl
    fi

    # Use a temporary location for gpg keys to avoid polluting image
    export GNUPGHOME="/tmp/tmp-gnupg"
    mkdir -p ${GNUPGHOME}
    chmod 700 ${GNUPGHOME}
    # GPG key download sometimes fails for some reason and retrying fixes it.
    local retry_count=0
    local gpg_ok="false"
    num_keys=$(echo ${keys} | wc -w)
    set +e
        echo "(*) Downloading GPG keys..."
        until [ "${gpg_ok}" = "true" ] || [ "${retry_count}" -eq "5" ]; do
            for keyserver in $(echo "$(get_gpg_key_servers)" | sed 's/keyserver //'); do
                ( echo "${keys}" | xargs -n 1 gpg -q ${keyring_args} --recv-keys --keyserver=${keyserver} ) 2>&1
                downloaded_keys=$(gpg --list-keys | grep ^pub | wc -l)
                if [[ ${num_keys} = ${downloaded_keys} ]]; then
                    gpg_ok="true"
                    break
                fi
            done
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
        local version_list="$(git ls-remote --tags ${repository} | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
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

# Use semver logic to decrement a version number then look for the closest match
find_prev_version_from_git_tags() {
    local variable_name=$1
    local current_version=${!variable_name}
    local repository=$2
    # Normally a "v" is used before the version number, but support alternate cases
    local prefix=${3:-"tags/v"}
    # Some repositories use "_" instead of "." for version number part separation, support that
    local separator=${4:-"."}
    # Some tools release versions that omit the last digit (e.g. go)
    local last_part_optional=${5:-"false"}
    # Some repositories may have tags that include a suffix (e.g. actions/node-versions)
    local version_suffix_regex=$6
    # Try one break fix version number less if we get a failure. Use "set +e" since "set -e" can cause failures in valid scenarios.
    set +e
        major="$(echo "${current_version}" | grep -oE '^[0-9]+' || echo '')"
        minor="$(echo "${current_version}" | grep -oP '^[0-9]+\.\K[0-9]+' || echo '')"
        breakfix="$(echo "${current_version}" | grep -oP '^[0-9]+\.[0-9]+\.\K[0-9]+' 2>/dev/null || echo '')"

        if [ "${minor}" = "0" ] && [ "${breakfix}" = "0" ]; then
            ((major=major-1))
            declare -g ${variable_name}="${major}"
            # Look for latest version from previous major release
            find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
        # Handle situations like Go's odd version pattern where "0" releases omit the last part
        elif [ "${breakfix}" = "" ] || [ "${breakfix}" = "0" ]; then
            ((minor=minor-1))
            declare -g ${variable_name}="${major}.${minor}"
            # Look for latest version from previous minor release
            find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
        else
            ((breakfix=breakfix-1))
            if [ "${breakfix}" = "0" ] && [ "${last_part_optional}" = "true" ]; then
                declare -g ${variable_name}="${major}.${minor}"
            else 
                declare -g ${variable_name}="${major}.${minor}.${breakfix}"
            fi
        fi
    set -e
}

add_symlink() {
    CURRENT_PATH="${PYTHON_INSTALL_PATH}/current"
    if [[ ! -d "${CURRENT_PATH}" ]]; then
        ln -s -r "${INSTALL_PATH}" "${CURRENT_PATH}" 
    fi

    if [ "${OVERRIDE_DEFAULT_VERSION}" = "true" ]; then
        if [[ $(ls -l ${CURRENT_PATH}) != *"-> ${INSTALL_PATH}"* ]] ; then
            rm "${CURRENT_PATH}"
            ln -s -r "${INSTALL_PATH}" "${CURRENT_PATH}" 
        fi
    fi
}

install_prev_vers_cpython() {
    VERSION=$1
    echo -e "\n(!) Failed to fetch the latest artifacts for cpython ${VERSION}..."
    find_prev_version_from_git_tags VERSION https://github.com/python/cpython
    echo -e "\nAttempting to install ${VERSION}"
    install_cpython "${VERSION}"
}

install_cpython() {
    VERSION=$1
    INSTALL_PATH="${PYTHON_INSTALL_PATH}/${VERSION}"
    mkdir -p /tmp/python-src ${INSTALL_PATH}
    cd /tmp/python-src
    cpython_tgz_filename="Python-${VERSION}.tgz"
    cpython_tgz_url="https://www.python.org/ftp/python/${VERSION}/${cpython_tgz_filename}"
    echo "Downloading ${cpython_tgz_filename}..."
    curl -sSL -o "/tmp/python-src/${cpython_tgz_filename}" "${cpython_tgz_url}"
}

install_from_source() {
    VERSION=$1  
    echo "(*) Building Python ${VERSION} from source..."
    echo "(*) Building Python ${VERSION} from source..."
    if ! type git > /dev/null 2>&1; then
        check_packages git
    fi

    echo -e "\nTrying to Install a fake version whose source binary wouldn't exist"
    VERSION="3.12.xyz"

    install_cpython "${VERSION}"
    if [ -f "/tmp/python-src/${cpython_tgz_filename}" ]; then
        if grep -q "404 Not Found" "/tmp/python-src/${cpython_tgz_filename}"; then
            # Use grep to search for "404 Not Found" in the file
            echo "\"404 Not Found\" found in /tmp/python-src/${cpython_tgz_filename}. Not able to create source binary"
            install_prev_vers_cpython "${VERSION}"
        fi
    fi;
    
    # Verify signature
    if [[ ${VERSION_CODENAME} = "centos7" ]] || [[ ${VERSION_CODENAME} = "rhel7" ]]; then
        receive_gpg_keys_centos7 PYTHON_SOURCE_GPG_KEYS
    else
        receive_gpg_keys PYTHON_SOURCE_GPG_KEYS
    fi

    echo "Downloading ${cpython_tgz_filename}.asc..."
    curl -sSL -o "/tmp/python-src/${cpython_tgz_filename}.asc" "${cpython_tgz_url}.asc"

    # Untar and build
    tar -xzf "/tmp/python-src/${cpython_tgz_filename}" -C "/tmp/python-src" --strip-components=1
    local config_args=""
 
    if [ "${OPTIMIZE_BUILD_FROM_SOURCE}" = "true" ]; then
        config_args="${config_args} --enable-optimizations"
    fi
    if [ "${ENABLESHARED}" = "true" ]; then
        config_args=" ${config_args} --enable-shared"
        # need double-$: LDFLAGS ends up in Makefile $$ becomes $ when evaluated.
        # backslash needed for shell that Make calls escape the $.
        export LDFLAGS="${LDFLAGS} -Wl,-rpath="'\$$ORIGIN'"/../lib"
    fi
    if [ -n "${ADDL_CONFIG_ARGS}" ]; then
        config_args="${config_args} ${ADDL_CONFIG_ARGS}"
    fi

    ./configure --prefix="${INSTALL_PATH}" --with-ensurepip=install ${config_args}
    make -j 8
    make install

    cd /tmp
    rm -rf /tmp/python-src ${GNUPGHOME} /tmp/vscdc-settings.env

    ln -s "${INSTALL_PATH}/bin/python3" "${INSTALL_PATH}/bin/python"
    ln -s "${INSTALL_PATH}/bin/pip3" "${INSTALL_PATH}/bin/pip"
    ln -s "${INSTALL_PATH}/bin/idle3" "${INSTALL_PATH}/bin/idle"
    ln -s "${INSTALL_PATH}/bin/pydoc3" "${INSTALL_PATH}/bin/pydoc"
    ln -s "${INSTALL_PATH}/bin/python3-config" "${INSTALL_PATH}/bin/python-config"

    add_symlink

}

install_from_source

check "Python version as installed by Fallback Test" bash -c "python3 -V"