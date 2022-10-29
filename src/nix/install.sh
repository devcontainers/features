#!/bin/bash
# Move to the same directory as this script
set -e
FEATURE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${FEATURE_DIR}"

# Option defaults
VERSION="${VERSION:-"latest"}"
MULTIUSER="${MULTIUSER:-"true"}"
PACKAGES="${PACKAGES//,/ }"
FLAKEURI="${FLAKEURI:-""}"
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"

# Nix keys for securly verifying installer download signature per https://nixos.org/download.html#nix-verify-installation
NIX_GPG_KEYS="B541D55301270E0BCF15CA5D8170B4726D7198DE"
GPG_KEY_SERVERS="keyserver hkp://keyserver.ubuntu.com:80
keyserver hkps://keys.openpgp.org
keyserver hkp://keyserver.pgp.com"

if [ -e "/nix" ]; then
    echo "(!) Nix is already installed! Aborting."
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Import common utils
. ./utils.sh

detect_user USERNAME
if [ "${USERNAME}" = "root" ] && [ "${MULTIUSER}" != "true" ]; then
    echo "(!) A single user install is not allowed for root. Add a non-root user to your image or set multiUser to true in your feature configuration."
    exit 1
fi

# Verify dependencies
apt_get_update_if_exists
check_command curl "curl ca-certificates" "curl ca-certificates" "curl ca-certificates"
check_command gpg2 gnupg2 gnupg gnupg2
check_command dirmngr dirmngr dirmngr dirmngr
check_command xz xz-utils xz xz
check_command git git git git
check_command xargs findutils findutils findutils

# Determine version
find_version_from_git_tags VERSION https://github.com/NixOS/nix "tags/"

# Download and verify install per https://nixos.org/download.html#nix-verify-installation
tmpdir="$(mktemp -d)"
echo "(*) Downloading Nix installer..."
set +e
curl -sSLf -o "${tmpdir}/install-nix" https://releases.nixos.org/nix/nix-${VERSION}/install
exit_code=$?
set -e
if [ "$exit_code" != "0" ]; then
    # Handle situation where git tags are ahead of what was is available to actually download
    echo "(!) Nix version ${VERSION} failed to download. Attempting to fall back one version to retry..."
    find_prev_version_from_git_tags VERSION https://github.com/NixOS/nix "tags/"
    curl -sSLf -o "${tmpdir}/install-nix" https://releases.nixos.org/nix/nix-${VERSION}/install
fi
curl -sSLf -o "${tmpdir}/install-nix.asc" https://releases.nixos.org/nix/nix-${VERSION}/install.asc
cd "${tmpdir}"
receive_gpg_keys NIX_GPG_KEYS
gpg2 --verify ./install-nix.asc
cd "${FEATURE_DIR}"

# Do a multi or single-user setup based on feature config
if [ "${MULTIUSER}" = "true" ]; then
    echo "(*) Performing multi-user install..."
    sh "${tmpdir}/install-nix" --daemon
else
    home_dir="$(eval echo ~${USERNAME})"
    if [ ! -e "${home_dir}" ]; then
        echo "(!) Home directory ${home_dir} does not exist for ${USERNAME}. Nix install will fail."
        exit 1
    fi
    echo "(*) Performing single-user install..."
    echo -e "\n**NOTE: Nix will only work for user ${USERNAME} on Linux if the host machine user's UID is $(id -u ${USERNAME}). You will need to chown /nix otherwise.**\n"    
    # Install per https://nixos.org/manual/nix/stable/installation/installing-binary.html#single-user-installation
    mkdir -p /nix
    chown ${USERNAME} /nix ${tmpdir}
    su ${USERNAME} -c "sh \"${tmpdir}/install-nix\" --no-daemon --no-modify-profile"
    # nix installer does not update ~/.bashrc, and USER may or may not be defined, so update rc/profile files directly to handle that
    snippet='
    if [ "${PATH#*$HOME/.nix-profile/bin}" = "${PATH}" ]; then if [ -z "$USER" ]; then USER=$(whoami); fi; . $HOME/.nix-profile/etc/profile.d/nix.sh; fi
    '
    update_rc_file "$home_dir/.bashrc" "${snippet}"
    update_rc_file "$home_dir/.zshenv" "${snippet}"
    update_rc_file "$home_dir/.profile" "${snippet}"    
fi
rm -rf "${tmpdir}" "/tmp/tmp-gnupg"

# Set nix config
mkdir -p /etc/nix
echo 'sandbox = false' >> /etc/nix/nix.conf
if  [ ! -z "${FLAKEURI}" ] && [ "${FLAKEURI}" != "none" ]; then
    echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
fi

# Create entrypoint if needed
if [ "${MULTIUSER}" = "true" ]; then
    echo "(*) Setting up entrypoint..."
    cp -f nix-entrypoint.sh /usr/local/share/
else
    echo -e '#!/bin/bash\nexec "$@"' > /usr/local/share/nix-entrypoint.sh
fi
chmod +x /usr/local/share/nix-entrypoint.sh

# Install packages, flakes, etc if specified
chmod +x,o+r ${FEATURE_DIR} ${FEATURE_DIR}/post-install-steps.sh
if [ "${MULTIUSER}" = "true" ]; then
    /usr/local/share/nix-entrypoint.sh
    su ${USERNAME} -c "
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        ${FEATURE_DIR}/post-install-steps.sh
    "
else
    su ${USERNAME} -c "
        . \$HOME/.nix-profile/etc/profile.d/nix.sh
        ${FEATURE_DIR}/post-install-steps.sh
    "
fi

echo "Done!"