#!/usr/bin/env sh
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/sshd.md
# Maintainer: The VS Code and Codespaces Teams
#
# Note: You can change your user's password with "sudo passwd $(whoami)" (or just "passwd" if running as root).

SSHD_PORT="${SSHD_PORT:-"2222"}"
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
START_SSHD="${START_SSHD:-"false"}"
NEW_PASSWORD="${NEW_PASSWORD:-"skip"}"

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, doas, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
. /etc/os-release
# Get an adjusted ID independent of distro variants
# Credit for POSIX substring checks: https://stackoverflow.com/a/8811800
MAJOR_VERSION_ID=$(echo ${VERSION_ID} | cut -d . -f 1)
if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
    ADJUSTED_ID="debian"
elif [ "${ID}" = "alpine" ]; then
    ADJUSTED_ID="alpine"
elif [ "${ID}" = "rhel" -o "${ID}" = "fedora" -o "${ID}" = "mariner" -o "${ID_LIKE}" != "${ID_LIKE#*rhel}" -o "${ID_LIKE}" != "${ID_LIKE#*fedora}" -o "${ID_LIKE}" != "${ID_LIKE#*mariner}" ]; then
    ADJUSTED_ID="rhel"
    if [ "${ID}" = "rhel" ] || [ "${ID}" != "${ID#*alma}" ] || [ "${ID}" != "${ID#*rocky}" ]; then
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
elif type apk > /dev/null 2>&1; then
    PKG_MGR_CMD=apk
    INSTALL_CMD="${PKG_MGR_CMD} add"
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

# Clean up
clean_up() {
    case ${ADJUSTED_ID} in
        debian)
            rm -rf /var/lib/apt/lists/*
            ;;
        alpine)
            rm -rf /var/cache/apk/*
            ;;
        rhel)
            rm -rf /var/cache/dnf/* /var/cache/yum/*
            rm -rf /tmp/yum.log
            rm -rf ${GPG_INSTALL_PATH}
            ;;
    esac
}
clean_up

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=$(echo $PATH | sed s@$(sh -lc 'echo $PATH')@\${PATH}@g)" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Some distributions do not install awk by default (e.g. Mariner)
if ! type awk >/dev/null 2>&1; then
    check_packages awk
fi

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    for CURRENT_USER in "vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)"; do
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

pkg_mgr_update() {
    case $ADJUSTED_ID in
        debian)
            if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
                echo "Running apt-get update..."
                ${PKG_MGR_CMD} update -y
            fi
            ;;
        alpine)
            if [ "$(find /var/cache/apk/* | wc -l)" = "0" ]; then
                echo "Running apk update..."
                ${PKG_MGR_CMD} update
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

# Checks if packages are installed and installs them if not
check_packages() {
    case ${ADJUSTED_ID} in
        debian)
            if ! dpkg -s "$@" > /dev/null 2>&1; then
                pkg_mgr_update
                ${INSTALL_CMD} "$@"
            fi
            ;;
        alpine)
            if ! apk -e "$@" > /dev/null 2>&1; then
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

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

# Install openssh-server openssh-client lsof openssl
case ${ADJUSTED_ID} in
    debian)
        check_packages openssh-server openssh-client lsof openssl
        ;;
    alpine)
        check_packages openssh-server openssh-client lsof openssl
        # Install openssh-server-pam for PAM, openrc for service
        check_packages openssh-server-pam openrc
        ;;
    rhel)
        # Include procps-ng for ps command
        check_packages openssh-server openssh-clients lsof openssl
        # Install procps-ng for ps, python3 docker systemctl replacement
        check_packages procps-ng python3 python3-pip
        pip3 install docker-systemctl-replacement --prefix /usr/local
        ;;
esac

# Generate password if new password set to the word "random"
if [ "${NEW_PASSWORD}" = "random" ]; then
    NEW_PASSWORD="$(openssl rand -hex 16)"
    EMIT_PASSWORD="true"
elif [ "${NEW_PASSWORD}" != "skip" ]; then
    # If new password not set to skip, set it for the specified user
    echo "${USERNAME}:${NEW_PASSWORD}" | chpasswd
fi

if [ $(getent group ssh) ]; then
    echo "'ssh' group already exists."
else
    echo "adding 'ssh' group, as it does not already exist."
    case ${ADJUSTED_ID} in
        debian|rhel)
            groupadd ssh
            ;;
        alpine)
            addgroup ssh
            ;;
    esac
fi

# Add user to ssh group
if [ "${USERNAME}" != "root" ]; then
    case ${ADJUSTED_ID} in
        debian|rhel)
            usermod -aG ssh ${USERNAME}
            ;;
        alpine)
            adduser ${USERNAME} ssh
            ;;
    esac
fi

# Setup sshd
mkdir -p /var/run/sshd
sed -i 's/session\s*required\s*pam_loginuid\.so/session optional pam_loginuid.so/g' /etc/pam.d/sshd
sed -i 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i -E "s/#*\s*Port\s+.+/Port ${SSHD_PORT}/g" /etc/ssh/sshd_config
# Need to UsePAM so /etc/environment is processed
sed -i -E "s/#?\s*UsePAM\s+.+/UsePAM yes/g" /etc/ssh/sshd_config
# Enable X11 forwarding
sed -i -E "s/#?\s*X11Forwarding\s+.+/X11Forwarding yes/g" /etc/ssh/sshd_config

# Ensure host keys are generated
ssh-keygen -A

# Write out a scripts that can be referenced as an ENTRYPOINT to auto-start sshd and fix login environments
tee /usr/local/share/ssh-init.sh > /dev/null \
<< 'EOF'
#!/usr/bin/env sh
# This script is intended to be run as root with a container that runs as root (even if you connect with a different user)
# However, it supports running as a user other than root if passwordless sudo or doas is configured for that same user.

set -e

if type sudo > /dev/null 2>&1; then
    DO_CMD=sudo
elif type doas > /dev/null 2>&1; then
    DO_CMD=doas
fi

sudoIf() {
    if [ "$(id -u)" -ne 0 ]; then
        ${DO_CMD} "$@"
    else
        "$@"
    fi
}
EOF

case ${ADJUSTED_ID} in
    debian)
        tee -a /usr/local/share/ssh-init.sh > /dev/null \
        << 'EOF'
# ** Start SSH server **
sudoIf /etc/init.d/ssh start 2>&1 | sudoIf tee /tmp/sshd.log > /dev/null

set +e
exec "$@"
EOF
        ;;
    alpine)
        tee -a /usr/local/share/ssh-init.sh > /dev/null \
        << 'EOF'
# ** Start SSH server **
# Initialize openrc to enable sufficient use of rc-service
if [ ! -d /run/openrc ]; then
    sudoIf openrc
    sudoIf touch /run/openrc/softlevel
fi
sudoIf rc-service sshd restart 2>&1 | sudoIf tee /tmp/sshd.log > /dev/null

set +e
exec "$@"
EOF
        ;;
    rhel)
        tee -a /usr/local/share/ssh-init.sh > /dev/null \
        << 'EOF'
# ** Start SSH server **
sudoIf /usr/local/bin/systemctl.py -vv start sshd.service 2>&1 | sudoIf tee /tmp/sshd.log > /dev/null

set +e
exec "$@"
EOF
        ;;
esac
chmod +x /usr/local/share/ssh-init.sh

# If we should start sshd now, do so
if [ "${START_SSHD}" = "true" ]; then
    /usr/local/share/ssh-init.sh
fi

# Output success details
echo -e "Done!\n\n- Port: ${SSHD_PORT}\n- User: ${USERNAME}"
if [ "${EMIT_PASSWORD}" = "true" ]; then
    echo "- Password: ${NEW_PASSWORD}"
fi

# Clean up
clean_up

echo -e "\nForward port ${SSHD_PORT} to your local machine and run:\n\n  ssh -p ${SSHD_PORT} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null ${USERNAME}@localhost\n"
