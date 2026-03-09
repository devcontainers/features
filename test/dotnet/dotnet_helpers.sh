#!/bin/bash

DOTNET_RELEASES_INDEX_URL="https://builds.dotnet.microsoft.com/dotnet/release-metadata/releases-index.json"

# Prints the latest active dotnet version from the releases index.
# Usage: fetch_latest_version [<target>]
# With no target, resolves the latest SDK version.
# With "sdk", resolves the latest SDK version explicitly.
# With "dotnet" or "aspnetcore", resolves the latest runtime version.
# Note: the upstream releases index only distinguishes SDK vs runtime for
# latest resolution, so "dotnet" and "aspnetcore" currently resolve to the
# same version.
# Example: fetch_latest_version
# Example: fetch_latest_version "sdk"
# Example: fetch_latest_version "dotnet"
# Example: fetch_latest_version "aspnetcore"
fetch_latest_version() {
    local target="$1"
    local version_field=""
    local releases_index=""

    case "$target" in
        ""|sdk)
            version_field="latest-sdk"
            ;;
        dotnet|aspnetcore)
            version_field="latest-runtime"
            ;;
        *)
            echo "Unsupported target '$target'. Expected 'sdk', 'dotnet', or 'aspnetcore'." >&2
            return 1
            ;;
    esac

    releases_index="$(wget -qO- "$DOTNET_RELEASES_INDEX_URL")" || return $?

    printf '%s\n' "$releases_index" \
        | jq -er --arg version_field "$version_field" '
            .["releases-index"]
            | map(
                select(."support-phase" == "active")
                | .[$version_field]
            )
            | .[0]
        '
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
