#!/usr/bin/env bash
set -e

GHCUP_VERSION="0.1.19.2"
GHCUP_BIN="x86_64-linux-ghcup-${GHCUP_VERSION}"
BOOTSTRAP_HASKELL_GHC_VERSION="${VERSION:-"recommended "}"

# Maybe install curl, gcc, make
for x in curl gcc make; do
    which $x > /dev/null || (apt update && apt install $x -y -qq)
done

GHCUP_DIR=~/.ghcup/bin
mkdir -p $GHCUP_DIR
curl https://downloads.haskell.org/~ghcup/${GHCUP_VERSION}/x86_64-linux-ghcup-${GHCUP_VERSION} --output ${GHCUP_BIN}
echo "25b7fc417c1a811dd7ff439b67ea647a59cf5b8d71b274f97e917d50b2150d5b ${GHCUP_BIN}" | sha256sum --check --status

mv ${GHCUP_BIN} $GHCUP_DIR/ghcup
chmod a+x $GHCUP_DIR/ghcup

${GHCUP_DIR}/ghcup install ghc $BOOTSTRAP_HASKELL_GHC_VERSION
${GHCUP_DIR}/ghcup install cabal $CABALVERSION
${GHCUP_DIR}/ghcup install hls $HLSVERSION
${GHCUP_DIR}/ghcup install stack $STACKVERSION

${GHCUP_DIR}/ghcup set ghc $BOOTSTRAP_HASKELL_GHC_VERSION
${GHCUP_DIR}/ghcup set cabal $CABALVERSION
${GHCUP_DIR}/ghcup set hls $HLSVERSION
${GHCUP_DIR}/ghcup set stack $STACKVERSION
