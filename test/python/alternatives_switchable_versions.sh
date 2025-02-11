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
    if [ "$STYLE" = "debian" ]; then
        while read -r alt && read -r pri; do
            PATH=${alt#Alternative: }   # Extract only the path
            PRIORITY=${pri#Priority: }  # Extract only the priority number
            AVAILABLE_VERSIONS+=("$PATH")
            echo "$INDEX) $PATH (Priority: $PRIORITY)"
            ((INDEX++))
        done <<< "${PYTHON_ALTERNATIVES}"
    elif [ "$STYLE" = "fedora" ]; then
        # Fedora/RHEL output: one line per alternative in the format:
        # /usr/local/python/3.11.11 - priority 4
        while IFS= read -r line; do
            # Split using " - priority " as a delimiter.
            SELECTED_PATH=$(echo "$line" | awk -F' - priority ' '{print $1}' | xargs)
            PRIORITY_VALUE=$(echo "$line" | awk -F' - priority ' '{print $2}' | xargs)
            AVAILABLE_VERSIONS+=("$SELECTED_PATH")
            echo "$INDEX) $SELECTED_PATH (Priority: $PRIORITY_VALUE)"
            ((INDEX++))
        done <<< "${PYTHON_ALTERNATIVES}"
    fi

    echo -e "\n"

    # Ensure at least 4 alternatives exist
    if [ "${#AVAILABLE_VERSIONS[@]}" -lt 4 ]; then
        echo "Error: Less than 4 Python versions registered in update-alternatives."
        exit 1
    fi

    for CHOICE in {1..4}; do
        SELECTED_VERSION="${AVAILABLE_VERSIONS[$((CHOICE - 1))]}"
        echo "Switching to: ${SELECTED_VERSION}"
        if type apt-get > /dev/null 2>&1; then
            /usr/bin/update-alternatives --set python3 ${SELECTED_VERSION}
        elif type dnf > /dev/null 2>&1 || type yum > /dev/null 2>&1 || type microdnf > /dev/null 2>&1; then
            /usr/sbin/alternatives --set python3 ${SELECTED_VERSION}
        fi

        # Verify the switch
        echo "Python version after switch:"
        /usr/local/python/current/bin/python3 --version

        /bin/sleep 2

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