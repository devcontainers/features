#!/bin/bash
# Copyright (c) .NET Foundation and contributors. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.
#
# Run this script to replace dotnet-install.sh with the latest and greatest available version
# 
dotnet_scripts=$(dirname "$BASH_SOURCE")
dotnet_install_script="$dotnet_scripts/dotnet-install.sh"

wget https://dot.net/v1/dotnet-install.sh -O "$dotnet_install_script"
chmod +x "$dotnet_install_script"
