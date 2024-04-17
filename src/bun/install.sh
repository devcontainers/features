#!/usr/bin/env bash

set -e

VERSION="${VERSION:-"latest"}"
export BUN_INSTALL=/usr/local

if [ "$VERSION" = "latest" ]; then
  curl -fsSL https://bun.sh/install | bash
else
  curl -fsSL https://bun.sh/install | bash -s -- "bun-v${VERSION}"
fi
