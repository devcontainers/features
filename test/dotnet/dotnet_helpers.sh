# Prints the latest SDK version in the specified channel
# Usage: fetch_latest_sdk_version_in_channel <channel>
# Example: fetch_latest_sdk_version_in_channel "LTS"
# Example: fetch_latest_sdk_version_in_channel "6.0"
fetch_latest_sdk_version_in_channel() {
    local channel="$1"
    wget -qO- "https://dotnetcli.azureedge.net/dotnet/Sdk/$channel/latest.version"
}

# Prints the latest SDK version
fetch_latest_sdk_version() {
    local latest_sts=$(fetch_latest_sdk_version_in_channel "STS")
    local latest_lts=$(fetch_latest_sdk_version_in_channel "LTS")
    if [[ "$latest_sts" > "$latest_lts" ]]; then
        echo "$latest_sts"
    else
        echo "$latest_lts"
    fi
}

# Asserts that the specified SDK version is installed
# Returns a non-zero exit code if the check fails
# Usage: is_dotnet_sdk_version_installed <version>
# Example: is_dotnet_sdk_version_installed "6.0"
# Example: is_dotnet_sdk_version_installed "6.0.412"
is_dotnet_sdk_version_installed() {
    local expected="$1"
    dotnet --list-sdks | grep -q $expected
    return $?
}