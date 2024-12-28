#!/bin/bash

# Prints the latest dotnet version in the specified channel
# Usage: fetch_latest_version_in_channel <channel> [<runtime>]
# Example: fetch_latest_version_in_channel "LTS"
# Example: fetch_latest_version_in_channel "6.0" "dotnet"
# Example: fetch_latest_version_in_channel "6.0" "aspnetcore"
fetch_latest_version_in_channel() {
    local channel="$1"
    local runtime="$2"
    if [ "$runtime" = "dotnet" ]; then
        wget -qO- "https://builds.dotnet.microsoft.com/dotnet/Runtime/$channel/latest.version"
    elif [ "$runtime" = "aspnetcore" ]; then
        wget -qO- "https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/$channel/latest.version"
    else
        wget -qO- "https://builds.dotnet.microsoft.com/dotnet/Sdk/$channel/latest.version"
    fi
}

# Prints the latest dotnet version
# Usage: fetch_latest_version [<runtime>]
# Example: fetch_latest_version
# Example: fetch_latest_version "dotnet"
# Example: fetch_latest_version "aspnetcore"
fetch_latest_version() {
    local runtime="$1"
    local sts_version
    local lts_version
    sts_version=$(fetch_latest_version_in_channel "STS" "$runtime")
    lts_version=$(fetch_latest_version_in_channel "LTS" "$runtime")
    if [[ "$sts_version" > "$lts_version" ]]; then
        echo "$sts_version"
    else
        echo "$lts_version"
    fi
}

# Asserts that the specified .NET SDK version is installed
# Returns a non-zero exit code if the check fails
# Usage: is_dotnet_sdk_version_installed <version>
# Example: is_dotnet_sdk_version_installed "6.0"
# Example: is_dotnet_sdk_version_installed "6.0.412"
is_dotnet_sdk_version_installed() {
    local expected="$1"
    dotnet --list-sdks | grep --fixed-strings --silent "$expected"
    return $?
}

# Asserts that the specified .NET Runtime version is installed
# Returns a non-zero exit code if the check fails
# Usage: is_dotnet_runtime_version_installed <version>
# Example: is_dotnet_runtime_version_installed "6.0"
# Example: is_dotnet_runtime_version_installed "6.0.412"
is_dotnet_runtime_version_installed() {
    local expected="$1"
    dotnet --list-runtimes | grep --fixed-strings --silent "Microsoft.NETCore.App $expected"
    return $?
}

# Asserts that the specified ASP.NET Core Runtime version is installed
# Returns a non-zero exit code if the check fails
# Usage: is_aspnetcore_runtime_version_installed <version>
# Example: is_aspnetcore_runtime_version_installed "6.0"
# Example: is_aspnetcore_runtime_version_installed "6.0.412"
is_aspnetcore_runtime_version_installed() {
    local expected="$1"
    dotnet --list-runtimes | grep --fixed-strings --silent "Microsoft.AspNetCore.App $expected"
    return $?
}

# Asserts that the specified workload is installed
# Returns a non-zero exit code if the check fails
# Usage: is_dotnet_workload_installed <workload_id>
# Example: is_dotnet_workload_installed "aspire"
is_dotnet_workload_installed() {
    local expected="$1"
    dotnet workload list | grep --fixed-strings --silent "$expected"
    return $?
}
