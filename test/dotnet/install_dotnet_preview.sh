#!/bin/bash

set -e

source dev-container-features-test-lib
source dotnet_env.sh
source dotnet_helpers.sh

# Verify 10.0 SDK (any prerelease containing '10.0') is installed
check ".NET SDK 10.0 installed" \
is_dotnet_sdk_version_installed "10.0"

check ".NET Runtime 10.0 installed" \
is_dotnet_runtime_version_installed "10.0"

check "ASP.NET Core Runtime 10.0 installed" \
is_aspnetcore_runtime_version_installed "10.0"

check "Build and run .NET 10.0 project" \
dotnet run --project projects/net10.0

reportResults
