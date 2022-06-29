set -e

# Optional: Import test library
source dev-container-features-test-lib

function expect () {
    local expected="$1"
    local actual="$2"
    if [ "$expected" != "$actual" ]; then
        echo "Expected: $expected"
        echo "Actual: $actual"
        exit 1
    fi
}

function string_contains () {
    local string="$1"
    local substring="$2"
    if [ "${string#*$substring}" != "$string" ]; then
        return 0
    else
        return 1
    fi
}
 
expect "version_on_path"           "v18.4.0"    "$(node -v)"
string_contains "v14_installed"    "v14.19.3"   "$(ls -1 /usr/local/share/nvm/versions/node)"
string_contains "v17_installed"    "v17.9.1"    "$(ls -1 /usr/local/share/nvm/versions/node)"


# Report result
reportResults
