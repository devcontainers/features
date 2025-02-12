#!/usr/bin/env bash

#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/dotnet
# Maintainer: The .NET Aspire team at https://github.com/dotnet/aspire

set -e

# default to latest if not specified
VERSION="${VERSION:-"latest"}"

if [[ ! $VERSION =~ ^(9\.0|latest|latest-daily)$ ]]; then
    echo "Error: VERSION must be either '9.0', '9.0.0', 'latest', or 'latest-daily' not: '$VERSION'."
    exit 1
fi

if [[ $VERSION =~ ^(9\.0|9\.0\.0|latest)$ ]]; then
    VERSION="9.0.0"
fi

echo "Activating feature '.NET Aspire' version: $VERSION"

# Before .NET Aspire 9.0 install required `dotnet workload`: this is no longer necessary, as Aspire is 
# installed when restoring Aspire projects. It's only necessary to install the appropriate version of the templates.


if [[ $VERSION =~ ^(9\.0\.0)$ ]]; then
    dotnet new install Aspire.ProjectTemplates::$VERSION
else
    # https://github.com/dotnet/aspire/blob/main/docs/using-latest-daily.md
    dotnet nuget add source --name dotnet9 https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet9/nuget/v3/index.json

    # If you use Package Source Mapping, you'll also need to add the following mappings to your NuGet.config
    # <packageSourceMapping>
    #   <packageSource key="dotnet9">
    #     <package pattern="Aspire.*" />
    #     <package pattern="Microsoft.Extensions.ServiceDiscovery*" />
    #     <package pattern="Microsoft.Extensions.Http.Resilience" />
    #   </packageSource>
    # </packageSourceMapping>

    dotnet new install Aspire.ProjectTemplates::*-* --force
fi

echo "... done activating feature '.NET Aspire' version: $VERSION"
