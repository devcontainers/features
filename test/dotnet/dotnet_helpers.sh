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
    local sts_version
    local lts_version
    sts_version=$(fetch_latest_sdk_version_in_channel "STS")
    lts_version=$(fetch_latest_sdk_version_in_channel "LTS")
    if [[ "$sts_version" > "$lts_version" ]]; then
        echo "$sts_version"
    else
        echo "$lts_version"
    fi
}

# Asserts that the specified SDK version is installed
# Returns a non-zero exit code if the check fails
# Usage: is_dotnet_sdk_version_installed <version>
# Example: is_dotnet_sdk_version_installed "6.0"
# Example: is_dotnet_sdk_version_installed "6.0.412"
is_dotnet_sdk_version_installed() {
    local expected="$1"
    dotnet --list-sdks | grep --fixed-strings --silent $expected
    return $?
}