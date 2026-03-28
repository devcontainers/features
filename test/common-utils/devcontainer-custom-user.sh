#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Check current user
current_user=$(whoami)
echo "Current user: $current_user"

# Check user's primary group ID
user_gid=$(id -g)
echo "User's primary GID: $user_gid"

# Check user's primary group name
user_group_name=$(id -gn)
echo "User's primary group name: $user_group_name"

# Check if user exists and get their info
if id -u vscode > /dev/null 2>&1; then
    echo "vscode user exists"
    vscode_uid=$(id -u vscode)
    vscode_gid=$(id -g vscode)
    vscode_group_name=$(id -gn vscode)
    
    echo "vscode UID: $vscode_uid"
    echo "vscode GID: $vscode_gid" 
    echo "vscode group name: $vscode_group_name"
else
    echo "vscode user does not exist"
fi

# Check what group has GID 100
if getent group 100 >/dev/null 2>&1; then
    group_100_info=$(getent group 100)
    echo "GID 100 belongs to: $group_100_info"
else
    echo "No group found with GID 100"
fi

# Check all groups the user belongs to
echo "All groups for $current_user: $(groups)"

# Definition specific tests based on the scenario
check "user is vscode" grep "vscode" <(whoami)
check "vscode user exists" id -u vscode
check "vscode primary group exists" id -g vscode

# If the test is specifically for GID 100, check that
if [ "$(id -g vscode)" = "100" ]; then
    check "vscode has GID 100" [ "$(id -g vscode)" = "100" ]
    check "GID 100 group name" getent group 100
fi

# Report result
reportResults