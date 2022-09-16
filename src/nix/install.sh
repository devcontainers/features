#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/sshd.md
# Maintainer: The VS Code and Codespaces Teams
#

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi


sh <(curl -L https://nixos.org/nix/install) --daemon

mkdir -p $HOME/.config/nix $HOME/.config/nixpkgs
echo 'sandbox = false' >> $HOME/.config/nix/nix.conf
echo '{ allowUnfree = true; }' >> $HOME/.config/nixpkgs/config.nix
echo '. $HOME/.nix-profile/etc/profile.d/nix.sh' >> $HOME/.bashrc