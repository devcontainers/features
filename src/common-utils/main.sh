#!/bin/bash
#-------------------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://github.com/devcontainers/features/blob/main/LICENSE for license information.
#-------------------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/common-utils
# Maintainer: The Dev Container spec maintainers

set -e

INSTALL_ZSH="${INSTALLZSH:-"true"}"
CONFIGURE_ZSH_AS_DEFAULT_SHELL="${CONFIGUREZSHASDEFAULTSHELL:-"false"}"
INSTALL_OH_MY_ZSH="${INSTALLOHMYZSH:-"true"}"
INSTALL_OH_MY_ZSH_CONFIG="${INSTALLOHMYZSHCONFIG:-"true"}"
UPGRADE_PACKAGES="${UPGRADEPACKAGES:-"true"}"
USERNAME="${USERNAME:-"automatic"}"
USER_UID="${USERUID:-"automatic"}"
USER_GID="${USERGID:-"automatic"}"
ADD_NON_FREE_PACKAGES="${NONFREEPACKAGES:-"false"}"

MARKER_FILE="/usr/local/etc/vscode-dev-containers/common"

FEATURE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Debian / Ubuntu packages
install_debian_packages() {
    # Ensure apt is in non-interactive to avoid prompts
    export DEBIAN_FRONTEND=noninteractive

    local package_list=""
    if [ "${PACKAGES_ALREADY_INSTALLED}" != "true" ]; then
        package_list="${package_list} \
        apt-utils \
        bash-completion \
        openssh-client \
        gnupg2 \
        dirmngr \
        iproute2 \
        procps \
        lsof \
        htop \
        net-tools \
        psmisc \
        curl \
        tree \
        wget \
        rsync \
        ca-certificates \
        unzip \
        bzip2 \
        xz-utils \
        zip \
        nano \
        vim-tiny \
        less \
        jq \
        lsb-release \
        apt-transport-https \
        dialog \
        libc6 \
        libgcc1 \
        libkrb5-3 \
        libgssapi-krb5-2 \
        libicu[0-9][0-9] \
        liblttng-ust[0-9] \
        libstdc++6 \
        zlib1g \
        locales \
        sudo \
        ncdu \
        man-db \
        strace \
        manpages \
        manpages-dev \
        init-system-helpers"

        # Include libssl1.1 if available
        if [[ ! -z $(apt-cache --names-only search ^libssl1.1$) ]]; then
            package_list="${package_list} libssl1.1"
        fi

        # Include libssl3 if available
        if [[ ! -z $(apt-cache --names-only search ^libssl3$) ]]; then
            package_list="${package_list} libssl3"
        fi

        # Include appropriate version of libssl1.0.x if available
        local libssl_package=$(dpkg-query -f '${db:Status-Abbrev}\t${binary:Package}\n' -W 'libssl1\.0\.?' 2>&1 || echo '')
        if [ "$(echo "$libssl_package" | grep -o 'libssl1\.0\.[0-9]:' | uniq | sort | wc -l)" -eq 0 ]; then
            if [[ ! -z $(apt-cache --names-only search ^libssl1.0.2$) ]]; then
                # Debian 9
                package_list="${package_list} libssl1.0.2"
            elif [[ ! -z $(apt-cache --names-only search ^libssl1.0.0$) ]]; then
                # Ubuntu 18.04
                package_list="${package_list} libssl1.0.0"
            fi
        fi

        # Include git if not already installed (may be more recent than distro version)
        if ! type git > /dev/null 2>&1; then
            package_list="${package_list} git"
        fi
    fi

    # Needed for adding manpages-posix and manpages-posix-dev which are non-free packages in Debian
    if [ "${ADD_NON_FREE_PACKAGES}" = "true" ]; then
        if [[ ! -e "/etc/apt/sources.list" ]] && [[ -e "/etc/apt/sources.list.d/debian.sources" ]]; then 
            sed -i '/^URIs: http:\/\/deb.debian.org\/debian$/ { N; N; s/Components: main/Components: main non-free non-free-firmware/ }' /etc/apt/sources.list.d/debian.sources
        else
            # Bring in variables from /etc/os-release like VERSION_CODENAME
            sed -i -E "s/deb http:\/\/(deb|httpredir)\.debian\.org\/debian ${VERSION_CODENAME} main/deb http:\/\/\1\.debian\.org\/debian ${VERSION_CODENAME} main contrib non-free/" /etc/apt/sources.list
            sed -i -E "s/deb-src http:\/\/(deb|httredir)\.debian\.org\/debian ${VERSION_CODENAME} main/deb http:\/\/\1\.debian\.org\/debian ${VERSION_CODENAME} main contrib non-free/" /etc/apt/sources.list
            sed -i -E "s/deb http:\/\/(deb|httpredir)\.debian\.org\/debian ${VERSION_CODENAME}-updates main/deb http:\/\/\1\.debian\.org\/debian ${VERSION_CODENAME}-updates main contrib non-free/" /etc/apt/sources.list
            sed -i -E "s/deb-src http:\/\/(deb|httpredir)\.debian\.org\/debian ${VERSION_CODENAME}-updates main/deb http:\/\/\1\.debian\.org\/debian ${VERSION_CODENAME}-updates main contrib non-free/" /etc/apt/sources.list
            sed -i "s/deb http:\/\/security\.debian\.org\/debian-security ${VERSION_CODENAME}\/updates main/deb http:\/\/security\.debian\.org\/debian-security ${VERSION_CODENAME}\/updates main contrib non-free/" /etc/apt/sources.list
            sed -i "s/deb-src http:\/\/security\.debian\.org\/debian-security ${VERSION_CODENAME}\/updates main/deb http:\/\/security\.debian\.org\/debian-security ${VERSION_CODENAME}\/updates main contrib non-free/" /etc/apt/sources.list
            sed -i "s/deb http:\/\/deb\.debian\.org\/debian ${VERSION_CODENAME}-backports main/deb http:\/\/deb\.debian\.org\/debian ${VERSION_CODENAME}-backports main contrib non-free/" /etc/apt/sources.list
            sed -i "s/deb-src http:\/\/deb\.debian\.org\/debian ${VERSION_CODENAME}-backports main/deb http:\/\/deb\.debian\.org\/debian ${VERSION_CODENAME}-backports main contrib non-free/" /etc/apt/sources.list
            # Handle bullseye location for security https://www.debian.org/releases/bullseye/amd64/release-notes/ch-information.en.html
            sed -i "s/deb http:\/\/security\.debian\.org\/debian-security ${VERSION_CODENAME}-security main/deb http:\/\/security\.debian\.org\/debian-security ${VERSION_CODENAME}-security main contrib non-free/" /etc/apt/sources.list
            sed -i "s/deb-src http:\/\/security\.debian\.org\/debian-security ${VERSION_CODENAME}-security main/deb http:\/\/security\.debian\.org\/debian-security ${VERSION_CODENAME}-security main contrib non-free/" /etc/apt/sources.list
        fi;
        echo "Running apt-get update..."
        package_list="${package_list} manpages-posix manpages-posix-dev"
    fi

    # Install the list of packages
    echo "Packages to verify are installed: ${package_list}"
    rm -rf /var/lib/apt/lists/*
    apt-get update -y
    apt-get -y install --no-install-recommends ${package_list} 2> >( grep -v 'debconf: delaying package configuration, since apt-utils is not installed' >&2 )

    # Install zsh (and recommended packages) if needed
    if [ "${INSTALL_ZSH}" = "true" ] && ! type zsh > /dev/null 2>&1; then
        apt-get install -y zsh
    fi

    # Get to latest versions of all packages
    if [ "${UPGRADE_PACKAGES}" = "true" ]; then
        apt-get -y upgrade --no-install-recommends
        apt-get autoremove -y
    fi

    # Ensure at least the en_US.UTF-8 UTF-8 locale is available = common need for both applications and things like the agnoster ZSH theme.
    if [ "${LOCALE_ALREADY_SET}" != "true" ] && ! grep -o -E '^\s*en_US.UTF-8\s+UTF-8' /etc/locale.gen > /dev/null; then
        echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
        locale-gen
        LOCALE_ALREADY_SET="true"
    fi

    PACKAGES_ALREADY_INSTALLED="true"

    # Clean up
    apt-get -y clean
    rm -rf /var/lib/apt/lists/*
}

# RedHat / RockyLinux / CentOS / Fedora packages
install_redhat_packages() {
    local package_list=""
    local remove_epel="false"
    local install_cmd=microdnf
    if ! type microdnf > /dev/null 2>&1; then
        install_cmd=dnf
        if ! type dnf > /dev/null 2>&1; then
            install_cmd=yum
        fi
    fi

    if [ "${PACKAGES_ALREADY_INSTALLED}" != "true" ]; then
        package_list="${package_list} \
            gawk \
            bash-completion \
            openssh-clients \
            gnupg2 \
            iproute \
            procps \
            lsof \
            net-tools \
            psmisc \
            wget \
            ca-certificates \
            rsync \
            unzip \
            xz \
            zip \
            nano \
            vim-minimal \
            less \
            jq \
            openssl-libs \
            krb5-libs \
            libicu \
            zlib \
            sudo \
            sed \
            grep \
            which \
            man-db \
            strace"

        # rockylinux:9 installs 'curl-minimal' which clashes with 'curl'
        # Install 'curl' for every OS except this rockylinux:9
        if [[ "${ID}" = "rocky" ]] && [[ "${VERSION}" != *"9."* ]]; then
            package_list="${package_list} curl"
        fi

        # Install OpenSSL 1.0 compat if needed
        if ${install_cmd} -q list compat-openssl10 >/dev/null 2>&1; then
            package_list="${package_list} compat-openssl10"
        fi

        # Install lsb_release if available
        if ${install_cmd} -q list redhat-lsb-core >/dev/null 2>&1; then
            package_list="${package_list} redhat-lsb-core"
        fi

        # Install git if not already installed (may be more recent than distro version)
        if ! type git > /dev/null 2>&1; then
            package_list="${package_list} git"
        fi

        # Install EPEL repository if needed (required to install 'jq' for CentOS)
        if ! ${install_cmd} -q list jq >/dev/null 2>&1; then
            ${install_cmd} -y install epel-release
            remove_epel="true"
        fi
    fi

    # Install zsh if needed
    if [ "${INSTALL_ZSH}" = "true" ] && ! type zsh > /dev/null 2>&1; then
        package_list="${package_list} zsh"
    fi

    if [ -n "${package_list}" ]; then
        ${install_cmd} -y install ${package_list}
    fi

    # Get to latest versions of all packages
    if [ "${UPGRADE_PACKAGES}" = "true" ]; then
        ${install_cmd} upgrade -y
    fi

    if [[ "${remove_epel}" = "true" ]]; then
        ${install_cmd} -y remove epel-release
    fi

    PACKAGES_ALREADY_INSTALLED="true"
}

# Alpine Linux packages
install_alpine_packages() {
    apk update

    if [ "${PACKAGES_ALREADY_INSTALLED}" != "true" ]; then
        apk add --no-cache \
            openssh-client \
            bash-completion \
            gnupg \
            procps \
            lsof \
            htop \
            net-tools \
            psmisc \
            curl \
            wget \
            rsync \
            ca-certificates \
            unzip \
            xz \
            zip \
            nano \
            vim \
            less \
            jq \
            libgcc \
            libstdc++ \
            krb5-libs \
            libintl \
            lttng-ust \
            tzdata \
            userspace-rcu \
            zlib \
            sudo \
            coreutils \
            sed \
            grep \
            which \
            ncdu \
            shadow \
            strace

        # # Include libssl1.1 if available (not available for 3.19 and newer)
        LIBSSL1_PKG=libssl1.1
        if [[ $(apk search --no-cache -a $LIBSSL1_PKG | grep $LIBSSL1_PKG) ]]; then
            apk add --no-cache $LIBSSL1_PKG
        fi

        # Install man pages - package name varies between 3.12 and earlier versions
        if apk info man > /dev/null 2>&1; then
            apk add --no-cache man man-pages
        else
            apk add --no-cache mandoc man-pages
        fi

        # Install git if not already installed (may be more recent than distro version)
        if ! type git > /dev/null 2>&1; then
            apk add --no-cache git
        fi
    fi

    # Install zsh if needed
    if [ "${INSTALL_ZSH}" = "true" ] && ! type zsh > /dev/null 2>&1; then
        apk add --no-cache zsh
    fi

    PACKAGES_ALREADY_INSTALLED="true"
}

# ******************
# ** Main section **
# ******************

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Load markers to see which steps have already run
if [ -f "${MARKER_FILE}" ]; then
    echo "Marker file found:"
    cat "${MARKER_FILE}"
    source "${MARKER_FILE}"
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
. /etc/os-release
# Get an adjusted ID independent of distro variants
if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
    ADJUSTED_ID="debian"
elif [[ "${ID}" = "rhel" || "${ID}" = "fedora" || "${ID}" = "mariner" || "${ID_LIKE}" = *"rhel"* || "${ID_LIKE}" = *"fedora"* || "${ID_LIKE}" = *"mariner"* ]]; then
    ADJUSTED_ID="rhel"
    VERSION_CODENAME="${ID}${VERSION_ID}"
elif [ "${ID}" = "alpine" ]; then
    ADJUSTED_ID="alpine"
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

# Install packages for appropriate OS
case "${ADJUSTED_ID}" in
    "debian")
        install_debian_packages
        ;;
    "rhel")
        install_redhat_packages
        ;;
    "alpine")
        install_alpine_packages
        ;;
esac

# If in automatic mode, determine if a user already exists, if not use vscode
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    if [ "${_REMOTE_USER}" != "root" ]; then
        USERNAME="${_REMOTE_USER}"
    else
        USERNAME=""
        POSSIBLE_USERS=("devcontainer" "vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
        for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
            if id -u ${CURRENT_USER} > /dev/null 2>&1; then
                USERNAME=${CURRENT_USER}
                break
            fi
        done
        if [ "${USERNAME}" = "" ]; then
            USERNAME=vscode
        fi
    fi
elif [ "${USERNAME}" = "none" ]; then
    USERNAME=root
    USER_UID=0
    USER_GID=0
fi
# Create or update a non-root user to match UID/GID.
group_name="${USERNAME}"
if id -u ${USERNAME} > /dev/null 2>&1; then
    # User exists, update if needed
    if [ "${USER_GID}" != "automatic" ] && [ "$USER_GID" != "$(id -g $USERNAME)" ]; then
        group_name="$(id -gn $USERNAME)"
        groupmod --gid $USER_GID ${group_name}
        usermod --gid $USER_GID $USERNAME
    fi
    if [ "${USER_UID}" != "automatic" ] && [ "$USER_UID" != "$(id -u $USERNAME)" ]; then
        usermod --uid $USER_UID $USERNAME
    fi
else
    # Create user
    if [ "${USER_GID}" = "automatic" ]; then
        groupadd $USERNAME
    else
        groupadd --gid $USER_GID $USERNAME
    fi
    if [ "${USER_UID}" = "automatic" ]; then
        useradd -s /bin/bash --gid $USERNAME -m $USERNAME
    else
        useradd -s /bin/bash --uid $USER_UID --gid $USERNAME -m $USERNAME
    fi
fi

# Add add sudo support for non-root user
if [ "${USERNAME}" != "root" ] && [ "${EXISTING_NON_ROOT_USER}" != "${USERNAME}" ]; then
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME
    chmod 0440 /etc/sudoers.d/$USERNAME
    EXISTING_NON_ROOT_USER="${USERNAME}"
fi

# *********************************
# ** Shell customization section **
# *********************************

if [ "${USERNAME}" = "root" ]; then
    user_home="/root"
# Check if user already has a home directory other than /home/${USERNAME}
elif [ "/home/${USERNAME}" != $( getent passwd $USERNAME | cut -d: -f6 ) ]; then
    user_home=$( getent passwd $USERNAME | cut -d: -f6 )
else
    user_home="/home/${USERNAME}"
    if [ ! -d "${user_home}" ]; then
        mkdir -p "${user_home}"
        chown ${USERNAME}:${group_name} "${user_home}"
    fi
fi

# Restore user .bashrc / .profile / .zshrc defaults from skeleton file if it doesn't exist or is empty
possible_rc_files=( ".bashrc" ".profile" )
[ "$INSTALL_OH_MY_ZSH_CONFIG" == "true" ] && possible_rc_files+=('.zshrc')
[ "$INSTALL_ZSH" == "true" ] && possible_rc_files+=('.zprofile')
for rc_file in "${possible_rc_files[@]}"; do
    if [ -f "/etc/skel/${rc_file}" ]; then
        if [ ! -e "${user_home}/${rc_file}" ] || [ ! -s "${user_home}/${rc_file}" ]; then
            cp "/etc/skel/${rc_file}" "${user_home}/${rc_file}"
            chown ${USERNAME}:${group_name} "${user_home}/${rc_file}"
        fi
    fi
done

# Add RC snippet and custom bash prompt
if [ "${RC_SNIPPET_ALREADY_ADDED}" != "true" ]; then
    case "${ADJUSTED_ID}" in
        "debian")
            global_rc_path="/etc/bash.bashrc"
            ;;
        "rhel")
            global_rc_path="/etc/bashrc"
            ;;
        "alpine")
            global_rc_path="/etc/bash/bashrc"
            # /etc/bash/bashrc does not exist in alpine 3.14 & 3.15
            mkdir -p /etc/bash
            ;;
    esac
    cat "${FEATURE_DIR}/scripts/rc_snippet.sh" >> ${global_rc_path}
    cat "${FEATURE_DIR}/scripts/bash_theme_snippet.sh" >> "${user_home}/.bashrc"
    if [ "${USERNAME}" != "root" ]; then
        cat "${FEATURE_DIR}/scripts/bash_theme_snippet.sh" >> "/root/.bashrc"
        chown ${USERNAME}:${group_name} "${user_home}/.bashrc"
    fi
    RC_SNIPPET_ALREADY_ADDED="true"
fi

# Optionally configure zsh and Oh My Zsh!
if [ "${INSTALL_ZSH}" = "true" ]; then
   if [ ! -f "${user_home}/.zprofile" ]; then
        touch "${user_home}/.zprofile"
        echo 'source $HOME/.profile' >> "${user_home}/.zprofile" # TODO: Reconsider adding '.profile' to '.zprofile'
        chown ${USERNAME}:${group_name} "${user_home}/.zprofile"
    fi

    if [ "${ZSH_ALREADY_INSTALLED}" != "true" ]; then
        if [ "${ADJUSTED_ID}" = "rhel" ]; then
             global_rc_path="/etc/zshrc"
        else
            global_rc_path="/etc/zsh/zshrc"
        fi
        cat "${FEATURE_DIR}/scripts/rc_snippet.sh" >> ${global_rc_path}
        ZSH_ALREADY_INSTALLED="true"
    fi

    if [ "${CONFIGURE_ZSH_AS_DEFAULT_SHELL}" == "true" ]; then
        # Fixing chsh always asking for a password on alpine linux
        # ref: https://askubuntu.com/questions/812420/chsh-always-asking-a-password-and-get-pam-authentication-failure.
        if [ ! -f "/etc/pam.d/chsh" ] || ! grep -Eq '^auth(.*)pam_rootok\.so$' /etc/pam.d/chsh; then
            echo "auth sufficient pam_rootok.so" >> /etc/pam.d/chsh
        elif [[ -n "$(awk '/^auth(.*)pam_rootok\.so$/ && !/^auth[[:blank:]]+sufficient[[:blank:]]+pam_rootok\.so$/' /etc/pam.d/chsh)" ]]; then
            awk '/^auth(.*)pam_rootok\.so$/ { $2 = "sufficient" } { print }' /etc/pam.d/chsh > /tmp/chsh.tmp && mv /tmp/chsh.tmp /etc/pam.d/chsh
        fi

        chsh --shell /bin/zsh ${USERNAME}
    fi

    # Adapted, simplified inline Oh My Zsh! install steps that adds, defaults to a codespaces theme.
    # See https://github.com/ohmyzsh/ohmyzsh/blob/master/tools/install.sh for official script.
    if [ "${INSTALL_OH_MY_ZSH}" = "true" ]; then
        user_rc_file="${user_home}/.zshrc"
        oh_my_install_dir="${user_home}/.oh-my-zsh"
        template_path="${oh_my_install_dir}/templates/zshrc.zsh-template"
        if [ ! -d "${oh_my_install_dir}" ]; then
            umask g-w,o-w
            mkdir -p ${oh_my_install_dir}
            git clone --depth=1 \
                -c core.eol=lf \
                -c core.autocrlf=false \
                -c fsck.zeroPaddedFilemode=ignore \
                -c fetch.fsck.zeroPaddedFilemode=ignore \
                -c receive.fsck.zeroPaddedFilemode=ignore \
                "https://github.com/ohmyzsh/ohmyzsh" "${oh_my_install_dir}" 2>&1

            # Shrink git while still enabling updates
            cd "${oh_my_install_dir}"
            git repack -a -d -f --depth=1 --window=1
        fi

        # Add Dev Containers theme
        mkdir -p ${oh_my_install_dir}/custom/themes
        cp -f "${FEATURE_DIR}/scripts/devcontainers.zsh-theme" "${oh_my_install_dir}/custom/themes/devcontainers.zsh-theme"
        ln -sf "${oh_my_install_dir}/custom/themes/devcontainers.zsh-theme" "${oh_my_install_dir}/custom/themes/codespaces.zsh-theme"

        # Add devcontainer .zshrc template
        if [ "$INSTALL_OH_MY_ZSH_CONFIG" = "true" ]; then
            echo -e "$(cat "${template_path}")\nDISABLE_AUTO_UPDATE=true\nDISABLE_UPDATE_PROMPT=true" > ${user_rc_file}
            sed -i -e 's/ZSH_THEME=.*/ZSH_THEME="devcontainers"/g' ${user_rc_file}
        fi

        # Copy to non-root user if one is specified
        if [ "${USERNAME}" != "root" ]; then
            copy_to_user_files=("${oh_my_install_dir}")
            [ -f "$user_rc_file" ] && copy_to_user_files+=("$user_rc_file")
            cp -rf "${copy_to_user_files[@]}" /root
            chown -R ${USERNAME}:${group_name} "${copy_to_user_files[@]}"
        fi
    fi
fi

# *********************************
# ** Ensure config directory **
# *********************************
user_config_dir="${user_home}/.config"
if [ ! -d "${user_config_dir}" ]; then
    mkdir -p "${user_config_dir}"
    chown ${USERNAME}:${group_name} "${user_config_dir}"
fi

# ****************************
# ** Utilities and commands **
# ****************************

# code shim, it fallbacks to code-insiders if code is not available
cp -f "${FEATURE_DIR}/bin/code" /usr/local/bin/
chmod +rx /usr/local/bin/code

# systemctl shim for Debian/Ubuntu - tells people to use 'service' if systemd is not running
if [ "${ADJUSTED_ID}" = "debian" ]; then
    cp -fL "${FEATURE_DIR}/bin/systemctl" /usr/local/bin/systemctl
    chmod +rx /usr/local/bin/systemctl
fi

# Persist image metadata info, script if meta.env found in same directory
if [ -f "/usr/local/etc/vscode-dev-containers/meta.env" ] || [ -f "/usr/local/etc/dev-containers/meta.env" ]; then
    cp -f "${FEATURE_DIR}/bin/devcontainer-info" /usr/local/bin/devcontainer-info
    chmod +rx /usr/local/bin/devcontainer-info
fi

# Write marker file
if [ ! -d "/usr/local/etc/vscode-dev-containers" ]; then
    mkdir -p "$(dirname "${MARKER_FILE}")"
fi
echo -e "\
    PACKAGES_ALREADY_INSTALLED=${PACKAGES_ALREADY_INSTALLED}\n\
    LOCALE_ALREADY_SET=${LOCALE_ALREADY_SET}\n\
    EXISTING_NON_ROOT_USER=${EXISTING_NON_ROOT_USER}\n\
    RC_SNIPPET_ALREADY_ADDED=${RC_SNIPPET_ALREADY_ADDED}\n\
    ZSH_ALREADY_INSTALLED=${ZSH_ALREADY_INSTALLED}" > "${MARKER_FILE}"

echo "Done!"
