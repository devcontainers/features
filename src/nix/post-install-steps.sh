#!/bin/bash
set -e
echo "(*) Executing post-installation steps..."

# Install list of packages in profile if specified.
if [ ! -z "${PACKAGES}" ] && [ "${PACKAGES}" != "none" ]; then
    echo "Installing packages \"${PACKAGES}\" in profile..."
    nix-env --install ${PACKAGES}
fi

# Install Nix flake in profile if specified
if [ ! -z "${FLAKEURI}" ] && [ "${FLAKEURI}" != "none" ]; then
    echo "Installing flake ${FLAKEURI} in profile..."
    nix profile install "${FLAKEURI}"
fi

nix-collect-garbage --delete-old
nix-store --optimise
