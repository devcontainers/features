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

# Function to resolve the actual version from an aka.ms URL
resolve_version_from_aka_ms() {
    local normalized_channel="${1:-LTS}"  # defaulting to LTS channel
    local normalized_product="dotnet-sdk"
    local normalized_os="linux"

    # Dynamically determine the architecture
    local normalized_architecture
    normalized_architecture=$(uname -m)
    case "$normalized_architecture" in
        x86_64) normalized_architecture="x64" ;;
        aarch64) normalized_architecture="arm64" ;;
        arm*) normalized_architecture="arm" ;;
        *) 
            echo "Unsupported architecture: $normalized_architecture"
            return 1
            ;;
    esac

    # Construct the aka.ms link
    local aka_ms_link="https://aka.ms/dotnet/$normalized_channel/$normalized_product-$normalized_os-$normalized_architecture.tar.gz"
    echo "Constructed aka.ms link: $aka_ms_link"

    # Resolve the redirect URL using curl
    local resolved_url
    resolved_url=$(curl -s -L -o /dev/null -w "%{url_effective}" "$aka_ms_link")
    echo "Resolved URL: $resolved_url"

    # Extract the version from the resolved URL
    IFS='/'
    read -ra pathElems <<< "$resolved_url"
    local count=${#pathElems[@]}
    local specific_version="${pathElems[count-2]}"
    unset IFS

    echo "Extracted version: $specific_version"
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
