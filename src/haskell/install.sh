#!/usr/bin/env bash
set -e

GHCUP_VERSION="0.1.19.2"
# Source /etc/os-release to get OS info
. /etc/os-release
# Fetch host/container arch.
architecture="$(dpkg --print-architecture)"
GHCUP_BIN="${architecture}-linux-ghcup-${GHCUP_VERSION}"

BOOTSTRAP_HASKELL_GHC_VERSION="${VERSION:-"recommended "}"

# Maybe install curl, gcc, make
for x in curl gcc make; do
    which $x > /dev/null || (apt update && apt install $x -y -qq)
done

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Determine the appropriate non-root user
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

GHCUP_DIR=${USERNAME}/.ghcup/bin
mkdir -p $GHCUP_DIR
curl https://downloads.haskell.org/~ghcup/${GHCUP_VERSION}/${architecture}-linux-ghcup-${GHCUP_VERSION} --output ${GHCUP_BIN}
echo "25b7fc417c1a811dd7ff439b67ea647a59cf5b8d71b274f97e917d50b2150d5b ${GHCUP_BIN}" | sha256sum --check --status

mv ${GHCUP_BIN} $GHCUP_DIR/ghcup
chmod a+x $GHCUP_DIR/ghcup

export GHCUP_INSTALL_BASE_PREFIX=${USERNAME}

${GHCUP_DIR}/ghcup install ghc $BOOTSTRAP_HASKELL_GHC_VERSION
${GHCUP_DIR}/ghcup install cabal $CABALVERSION
${GHCUP_DIR}/ghcup install hls $HLSVERSION
${GHCUP_DIR}/ghcup install stack $STACKVERSION

${GHCUP_DIR}/ghcup set ghc $BOOTSTRAP_HASKELL_GHC_VERSION
${GHCUP_DIR}/ghcup set cabal $CABALVERSION
${GHCUP_DIR}/ghcup set hls $HLSVERSION
${GHCUP_DIR}/ghcup set stack $STACKVERSION

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
