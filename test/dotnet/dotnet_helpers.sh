#!/bin/bash

# Include the same helper functions used by the install script
source ".devcontainer/dotnet/scripts/dotnet-helpers.sh"

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
