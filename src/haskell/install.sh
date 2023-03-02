#!/usr/bin/env bash
set -e

BOOTSTRAP_HASKELL_GHC_VERSION="${VERSION:-"recommended "}"

# Maybe install curl, gcc, make
for x in curl gcc make; do
    which $x > /dev/null || (apt update && apt install $x -y -qq)
done

curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 BOOTSTRAP_HASKELL_MINIMAL=1 sh
 
GHCUP_DIR=~/.ghcup/bin

${GHCUP_DIR}/ghcup install ghc $BOOTSTRAP_HASKELL_GHC_VERSION
${GHCUP_DIR}/ghcup install cabal $CABAL_VERSION
${GHCUP_DIR}/ghcup install hls $HLS_VERSION
${GHCUP_DIR}/ghcup install stack $STACK_VERSION

${GHCUP_DIR}/ghcup set ghc $BOOTSTRAP_HASKELL_GHC_VERSION
${GHCUP_DIR}/ghcup set cabal $CABAL_VERSION
${GHCUP_DIR}/ghcup set hls $HLS_VERSION
${GHCUP_DIR}/ghcup set stack $STACK_VERSION
