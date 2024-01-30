#!/bin/bash
set -e
echo "(*) Executing post-installation steps..."

# if not starts with "nixpkgs." add it as prefix to package name
add_nixpkgs_prefix() {
  local packages=$1
  local -a addr
  IFS=' ' read -ra addr <<<"$packages"
  for i in "${!addr[@]}"; do
    if [[ ${addr[i]} != nixpkgs.* ]]; then
      addr[i]="nixpkgs.${addr[i]}"
    fi
  done
  IFS=' ' echo "${addr[*]}"
}

# Install list of packages in profile if specified.
if [ ! -z "${PACKAGES}" ] && [ "${PACKAGES}" != "none" ]; then
  if [ "${USEATTRIBUTEPATH}" = "true" ]; then
    PACKAGES=$(add_nixpkgs_prefix "$PACKAGES")
    echo "Installing packages \"${PACKAGES}\" in profile..."
    nix-env -iA ${PACKAGES}
  else
    echo "Installing packages \"${PACKAGES}\" in profile..."
    nix-env --install ${PACKAGES}
  fi
fi

# Install Nix flake in profile if specified
if [ ! -z "${FLAKEURI}" ] && [ "${FLAKEURI}" != "none" ]; then
    echo "Installing flake ${FLAKEURI} in profile..."
    nix profile install "${FLAKEURI}"
fi

nix-collect-garbage --delete-old
nix-store --optimise
