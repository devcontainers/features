#!/bin/bash

set -e

export DOTNET_NOLOGO=true
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=true
export DOTNET_GENERATE_ASPNET_CERTIFICATE=false

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md#dev-container-features-test-lib
# Provides the 'check' and 'reportResults' commands.
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib. Syntax is...
# check <LABEL> <cmd> [args...]

fetch_latest_sdk_version_in_channel() {
    local channel="$1"
    wget -qO- "https://dotnetcli.azureedge.net/dotnet/Sdk/$channel/latest.version"
}

is_installed_dotnet_sdk_version() {
    local version="$1"
    dotnet --list-sdks | grep -q $version
    return $?
}

latest_sts=$(fetch_latest_sdk_version_in_channel "STS")

check "Latest STS version installed" is_installed_dotnet_sdk_version $latest_sts 
check "Example project" dotnet run --project projects/net7.0 

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults