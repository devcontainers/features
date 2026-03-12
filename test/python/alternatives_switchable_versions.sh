#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "python version 3.11 installed as default" bash -c "python --version | grep 3.11"
check "python3 version 3.11 installed as default" bash -c "python3 --version | grep 3.11"
check "python version 3.10.5 installed"  bash -c "ls -l /usr/local/python | grep 3.10.5"
check "python version 3.8 installed"  bash -c "ls -l /usr/local/python | grep 3.8"
check "python version 3.9.13 installed"  bash -c  "ls -l /usr/local/python | grep 3.9.13"

# Check paths in settings
check "current symlink is correct" bash -c "which python | grep /usr/local/python/current/bin/python"
check "current symlink works" /usr/local/python/current/bin/python --version

# check alternatives command
check_version_switch() {
    if type apt-get > /dev/null 2>&1; then
        PYTHON_ALTERNATIVES=$(update-alternatives --query python3 | grep -E 'Alternative:|Priority:')
        STYLE="debian"
    elif type dnf > /dev/null 2>&1 || type yum > /dev/null 2>&1 || type microdnf > /dev/null 2>&1; then
        PYTHON_ALTERNATIVES=$(alternatives --display python3 | grep " - priority")
        STYLE="fedora"
    else
        echo "No supported package manager found."
        exit 1
    fi

    AVAILABLE_VERSIONS=()
    INDEX=1
    echo "Available Python versions:"
    if [ "${STYLE}" = "debian" ]; then
        while read -r alt && read -r pri; do
            PATH=${alt#Alternative: }   # Extract only the path
            PRIORITY=${pri#Priority: }  # Extract only the priority number
            TEMP_VERSIONS+=("${PRIORITY} ${PATH}")
            echo "$INDEX) $PATH (Priority: $PRIORITY)"
            ((INDEX++))
        done <<< "${PYTHON_ALTERNATIVES}"
    elif [ "${STYLE}" = "fedora" ]; then
        export PATH="/usr/bin:$PATH"
        # Fedora/RHEL output: one line per alternative in the format:
        while IFS= read -r line; do
            # Split using " - priority " as a delimiter.
            PATH=$(/usr/bin/awk -F' - priority ' '{print $1}' <<< "$line" | /usr/bin/xargs /bin/echo)
            PRIORITY=$(/usr/bin/awk -F' - priority ' '{print $2}' <<< "$line" | /usr/bin/xargs /bin/echo)    
            TEMP_VERSIONS+=("${PRIORITY} ${PATH}") 
            echo "$INDEX) $PATH (Priority: $PRIORITY_VALUE)"
            ((INDEX++))
        done <<< "${PYTHON_ALTERNATIVES}"
    fi

    export PATH="/usr/bin:$PATH"
    # Sort by priority (numerically ascending)
    IFS=$'\n' TEMP_VERSIONS=($(sort -n <<<"${TEMP_VERSIONS[*]}"))
    unset IFS

    # Populate AVAILABLE_VERSIONS from sorted data
    AVAILABLE_VERSIONS=()
    INDEX=1
    echo -e "\nAvailable Python versions (Sorted in asc order of priority):"
    for ENTRY in "${TEMP_VERSIONS[@]}"; do
        PRIORITY=${ENTRY%% *}  # Extract priority (first part before space)
        PATH=${ENTRY#* }       # Extract path (everything after first space)
        AVAILABLE_VERSIONS+=("${PATH}")
        echo "$INDEX) $PATH (Priority: $PRIORITY)"
        ((INDEX++))
    done

    echo -e "\nAvailable Versions Count: ${#AVAILABLE_VERSIONS[@]}"
    # Ensure at least 4 alternatives exist
    if [ "${#AVAILABLE_VERSIONS[@]}" -lt 4 ]; then
        echo "Error: Less than 4 Python versions registered in update-alternatives."
        exit 1
    fi
    
    export PATH="/usr/bin:$PATH"
    echo -e "\nSwitching to different versions using update-alternatives --set command...\n"
    for CHOICE in {1..4}; do
        SELECTED_VERSION="${AVAILABLE_VERSIONS[$((CHOICE - 1))]}"
        echo "Switching to: ${SELECTED_VERSION}"
        if command -v apt-get > /dev/null 2>&1; then
            /usr/bin/update-alternatives --set python3 ${SELECTED_VERSION}
        elif command -v dnf > /dev/null 2>&1 || command -v yum > /dev/null 2>&1 || command -v microdnf > /dev/null 2>&1; then
            /usr/sbin/alternatives --set python3 ${SELECTED_VERSION}
        fi
        # Verify the switch
        echo "Python version after switch:"
        /usr/local/python/current/bin/python3 --version
        /bin/sleep 1
        echo -e "\n"
    done
    echo -e "Update-Alternatives --display: \n"
    if type apt-get > /dev/null 2>&1; then
        /usr/bin/update-alternatives --display python3
    elif type dnf > /dev/null 2>&1 || type yum > /dev/null 2>&1 || type microdnf > /dev/null 2>&1; then
        /usr/sbin/alternatives --display python3
    fi
}

check "Version Switch With Update_Alternatives" check_version_switch