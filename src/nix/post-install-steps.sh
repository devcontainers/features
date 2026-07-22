#!/bin/bash
set -e
echo "(*) Executing post-installation steps..."

# In multi-user mode, install into the default profile that is on PATH.
NIX_ENV_PROFILE_ARGS=()
NIX_PROFILE_INSTALL_ARGS=()
if [ -n "${NIX_FEATURE_INSTALL_PROFILE}" ]; then
  NIX_ENV_PROFILE_ARGS=(-p "${NIX_FEATURE_INSTALL_PROFILE}")
  NIX_PROFILE_INSTALL_ARGS=(--profile "${NIX_FEATURE_INSTALL_PROFILE}")
fi

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
    nix-env "${NIX_ENV_PROFILE_ARGS[@]}" -iA ${PACKAGES}
  else
    echo "Installing packages \"${PACKAGES}\" in profile..."
    nix-env "${NIX_ENV_PROFILE_ARGS[@]}" --install ${PACKAGES}
  fi
fi

# Install Nix flake in profile if specified
if [ ! -z "${FLAKEURI}" ] && [ "${FLAKEURI}" != "none" ]; then
    echo "Installing flake ${FLAKEURI} in profile..."
  nix profile install "${NIX_PROFILE_INSTALL_ARGS[@]}" "${FLAKEURI}"
fi

nix-collect-garbage --delete-old
nix-store --optimise
