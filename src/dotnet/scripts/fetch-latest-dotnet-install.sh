#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/dotnet
# Maintainer: The Dev Container spec maintainers
#
# Run this script to replace dotnet-install.sh with the latest and greatest available version
# 
DOTNET_SCRIPTS=$(dirname "${BASH_SOURCE[0]}")
DOTNET_INSTALL_SCRIPT="$DOTNET_SCRIPTS/vendor/dotnet-install.sh"

wget https://dot.net/v1/dotnet-install.sh -O "$DOTNET_INSTALL_SCRIPT"
chmod +x "$DOTNET_INSTALL_SCRIPT"
