# Function to run apt-get if needed
apt_get_update_if_needed()
{
    export DEBIAN_FRONTEND=noninteractive
    if [ ! -d "/var/lib/apt/lists" ] || [ "$(ls /var/lib/apt/lists/ | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update
    else
        echo "Skipping apt-get update."
    fi
}

# Function to run apt-get if command exists
apt_get_update_if_exists()
{
    if type apt-get > /dev/null 2>&1; then
        apt-get update
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if type dpkg > /dev/null 2>&1 && dpkg -s $1 > /dev/null 2>&1; then
        return 0
    elif type apk > /dev/null 2>&1 && apk -e info $2 > /dev/null 2>&1; then
        return 0
    elif type rpm > /dev/null 2>&1 && rpm -q $3 > /dev/null 2>&1; then
        return 0
    else
        echo "Unable to find package manager to check for packages."
        exit 1
    fi
    install_packages "$@"
    return $?
}

# Checks if command exists, installs it if not
# check_command <command> "<apt packages to install>" "<apk packages to install>" "<dnf/yum packages to install>"
check_command() {
    command_to_check=$1
    shift
    if type "${command_to_check}" > /dev/null 2>&1; then
        return 0
    fi
    install_packages "$@"
    return $?
}

# Installs packages using the appropriate package manager (apt, apk, dnf, or yum)
# install_packages "<apt packages to install>" "<apk packages to install>" "<dnf/yum packages to install>"
install_packages() {
    if type apt-get > /dev/null 2>&1; then
        apt_get_update_if_needed
        apt-get -y install --no-install-recommends $1
    elif type apk > /dev/null 2>&1; then
        apk add $2
    elif type dnf > /dev/null 2>&1; then
        dnf install -y $3
    elif type yum > /dev/null 2>&1; then
        yum install -y $3
    else
        echo "Unable to find package manager to install ${command_to_check}"
        exit 1
    fi
}

# If in automatic mode, determine if a user already exists, if not use root
detect_user() {
    local user_variable_name=${1:-username}
    local possible_users=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    if [ "${!user_variable_name}" = "auto" ] || [ "${!user_variable_name}" = "automatic" ]; then
        declare -g ${user_variable_name}=""
        for current_user in ${possible_users[@]}; do
            if id -u "${current_user}" > /dev/null 2>&1; then
                declare -g ${user_variable_name}="${current_user}"
                break
            fi
        done
    fi
    if [ "${!user_variable_name}" = "" ] || [ "${!user_variable_name}" = "none" ] || ! id -u "${!user_variable_name}" > /dev/null 2>&1; then
        declare -g ${user_variable_name}=root
    fi
}

# Figure out correct version of a three part version number is not passed
find_version_from_git_tags() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    # Normally a "v" is used before the version number, but support alternate cases
    local prefix=${3:-"tags/v"}
    # Some repositories use "_" instead of "." for version number part separation, support that
    local separator=${4:-"."}
    # Some tools release versions that omit the last digit (e.g. go)
    local last_part_optional=${5:-"false"}
    # Some repositories may have tags that include a suffix (e.g. actions/node-versions)
    local version_suffix_regex=$6

    local escaped_separator=${separator//./\\.}
    local break_fix_digit_regex
    if [ "${last_part_optional}" = "true" ]; then
        break_fix_digit_regex="(${escaped_separator}[0-9]+)?"
    else
        break_fix_digit_regex="${escaped_separator}[0-9]+"
    fi    
    local version_regex="[0-9]+${escaped_separator}[0-9]+${break_fix_digit_regex}${version_suffix_regex//./\\.}"
    # If we're passed a matching version number, just return it, otherwise look for a version
    if ! echo "${requested_version}" | grep -E "^${versionMatchRegex}$" > /dev/null 2>&1; then
        local version_list="$(git ls-remote --tags ${repository} | grep -oP "${prefix}\\K${version_regex}$" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            declare -g ${variable_name}="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            declare -g ${variable_name}="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|${version_suffix_regex//./\\.}|$)")"
            set -e
        fi
        if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" > /dev/null 2>&1; then
            echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
            exit 1
        fi
    fi
    echo "Adjusted ${variable_name}=${!variable_name}"
}

# Soft version matching that resolves a version for a given package in the *current apt-cache*
# Return value is stored in first argument (the unprocessed version)
apt_cache_version_soft_match() {
    # Version
    local variable_name="$1"
    local requested_version=${!variable_name}
    # Package Name
    local package_name="$2"
    # Exit on no match?
    local exit_on_no_match="${3:-true}"

    # Ensure we've exported useful variables
    . /etc/os-release
    local architecture="$(dpkg --print-architecture)"
    
    dot_escaped="${requested_version//./\\.}"
    dot_plus_escaped="${dot_escaped//+/\\+}"
    # Regex needs to handle debian package version number format: https://www.systutorials.com/docs/linux/man/5-deb-version/
    version_regex="^(.+:)?${dot_plus_escaped}([\\.\\+ ~:-]|$)"
    set +e # Don't exit if finding version fails - handle gracefully
        fuzzy_version="$(apt-cache madison ${package_name} | awk -F"|" '{print $2}' | sed -e 's/^[ \t]*//' | grep -E -m 1 "${version_regex}")"
    set -e
    if [ -z "${fuzzy_version}" ]; then
        echo "(!) No full or partial for package \"${package_name}\" match found in apt-cache for \"${requested_version}\" on OS ${ID} ${VERSION_CODENAME} (${architecture})."

        if $exit_on_no_match; then
            echo "Available versions:"
            apt-cache madison ${package_name} | awk -F"|" '{print $2}' | grep -oP '^(.+:)?\K.+'
            exit 1 # Fail entire script
        else
            echo "Continuing to fallback method (if available)"
            return 1;
        fi
    fi

    # Globally assign fuzzy_version to this value
    # Use this value as the return value of this function
    declare -g ${variable_name}="=${fuzzy_version}"
    echo "${variable_name}=${!variable_name}"
}

# Checks if a marker file exists with the correct contents
# check_marker <marker path> [argument to be validated]...
check_marker() {
    local marker_path="$1"
    shift
    local verifier_string="$(echo "$@")"
    if [ -e "${marker_path}" ] && [ "${verifier_string}" = "$(cat ${marker_path})" ]; then
        return 1
    else 
        return 0
    fi
}

# Updates marker for future checking
# update_marker <marker path> [argument to be validated]...
update_marker() {
    local marker_path="$1"
    shift
    mkdir -p "$(dirname "${marker_path}")"
    echo "$(echo "$@")" > "${marker_path}"
}

# run_if_exists <command> <command arguments>...
run_if_exists() {
    if [ -e "$1" ]; then
        "$@"
    fi
}

# run_as_user_if_exists <username> <command> <command arguments>...
run_as_user_if_exists() {
    local username=$1
    shift
    if [ -e "$1" ]; then
        local command_string="$@"
        su "${username}" -c "${command_string//"/\\"}"
    fi
}

# symlink_if_ne <source> <target>
symlink_if_ne() {
    if [ ! -e "$2" ]; then
        ln -s "$1" "$2"
    fi
}

# Update a rc/profile file if it exists and string is not already present
update_rc_file() {
    # see if folder containing file exists
    local rc_file_folder="$(dirname "$1")"
    if [ ! -d "${rc_file_folder}" ]; then
        echo "${rc_file_folder} does not exist. Skipping update of $1."
    elif [ ! -e "$1" ] || [[ "$(cat "$1")" != *"$2"* ]]; then
        echo "$2" >> "$1"
    fi
}

# Update a file if with string if not already present
# create_or_update_file <file> <string>
create_or_update_file() {
    if [ ! -e "$1" ] || [[ "$(cat "$1")" != *"$2"* ]]; then
        echo "$2" >> "$1"
    fi
}

# Use semver logic to decrement a version number then look for the closest match
find_prev_version_from_git_tags() {
    local variable_name=$1
    local current_version=${!variable_name}
    local repository=$2
    # Normally a "v" is used before the version number, but support alternate cases
    local prefix=${3:-"tags/v"}
    # Some repositories use "_" instead of "." for version number part separation, support that
    local separator=${4:-"."}
    # Some tools release versions that omit the last digit (e.g. go)
    local last_part_optional=${5:-"false"}
    # Some repositories may have tags that include a suffix (e.g. actions/node-versions)
    local version_suffix_regex=$6
    # Try one break fix version number less if we get a failure. Use "set +e" since "set -e" can cause failures in valid scenarios.
    set +e
    major="$(echo "${current_version}" | grep -oE '^[0-9]+' || echo '')"
    minor="$(echo "${current_version}" | grep -oP '^[0-9]+\.\K[0-9]+' || echo '')"
    breakfix="$(echo "${current_version}" | grep -oP '^[0-9]+\.[0-9]+\.\K[0-9]+' 2>/dev/null || echo '')"

    if [ "${minor}" = "0" ] && [ "${breakfix}" = "0" ]; then
        ((major=major-1))
        declare -g ${variable_name}="${major}"
        # Look for latest version from previous major release
        find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
    # Handle situations like Go's odd version pattern where "0" releases omit the last part
    elif [ "${breakfix}" = "" ] || [ "${breakfix}" = "0" ]; then
        ((minor=minor-1))
        declare -g ${variable_name}="${major}.${minor}"
        # Look for latest version from previous minor release
        find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
    else
        ((breakfix=breakfix-1))
        if [ "${breakfix}" = "0" ] && [ "${last_part_optional}" = "true" ]; then
            declare -g ${variable_name}="${major}.${minor}"
        else 
            declare -g ${variable_name}="${major}.${minor}.${breakfix}"
        fi
    fi

    set -e
}