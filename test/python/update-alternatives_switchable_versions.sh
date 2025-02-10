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

# check update-alternatives command

check_version_switch() {
    PYTHON_ALTERNATIVES=$(update-alternatives --query python3 | grep -E 'Alternative:|Priority:')
    AVAILABLE_VERSIONS=()
    INDEX=1

    echo "Available Python versions:"
    while read -r alt && read -r pri; do
        PATH=${alt#Alternative: }   # Extract only the path
        PRIORITY=${pri#Priority: }  # Extract only the priority number
        AVAILABLE_VERSIONS+=("$PATH")
        echo "$INDEX) $PATH (Priority: $PRIORITY)"
        ((INDEX++))
    done <<< "${PYTHON_ALTERNATIVES}"

    echo -e "\n"

    # Ensure at least 4 alternatives exist
    if [ "${#AVAILABLE_VERSIONS[@]}" -lt 4 ]; then
        echo "Error: Less than 4 Python versions registered in update-alternatives."
        exit 1
    fi

    for CHOICE in {1..4}; do
        SELECTED_VERSION="${AVAILABLE_VERSIONS[$((CHOICE - 1))]}"
        echo "Switching to: ${SELECTED_VERSION}"
        /usr/bin/update-alternatives --set python3 ${SELECTED_VERSION}

        # Verify the switch
        echo "Python version after switch:"
        /usr/local/python/current/bin/python3 --version

        /bin/sleep 2

        echo -e "\n"
    done
    echo -e "Update-Alternatives --display: \n"
    /usr/bin/update-alternatives --display python3
}

check "Version Switch With Update_Alternatives" check_version_switch