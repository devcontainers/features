#!/bin/bash
#-------------------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://github.com/devcontainers/features/blob/main/LICENSE for license information.
#-------------------------------------------------------------------------------------------------------------------------
#
# Helper script for common feature setup tasks, including user selection logic.
# Maintainer: The Dev Container spec maintainers

# Determine the appropriate non-root user
# Usage: determine_user_from_input USERNAME [FALLBACK_USER]
#
# This function resolves the USERNAME variable based on the input value:
# - If USERNAME is "auto" or "automatic", it will detect an existing non-root user
# - If USERNAME is "none" or doesn't exist, it will fall back to root
# - Otherwise, it validates the specified USERNAME exists
#
# Arguments:
#   USERNAME - The username input (typically from feature configuration)
#   FALLBACK_USER - Optional fallback user when no user is found in automatic mode (defaults to "root")
#
# Returns:
#   The resolved username is printed to stdout
#
# Examples:
#   USERNAME=$(determine_user_from_input "automatic")
#   USERNAME=$(determine_user_from_input "vscode")
#   USERNAME=$(determine_user_from_input "auto" "vscode")
#
determine_user_from_input() {
    local input_username="${1:-automatic}"
    local fallback_user="${2:-root}"
    local resolved_username=""

    if [ "${input_username}" = "auto" ] || [ "${input_username}" = "automatic" ]; then
        # Automatic mode: try to detect an existing non-root user
        
        # First, check if _REMOTE_USER is set and is not root
        if [ -n "${_REMOTE_USER:-}" ] && [ "${_REMOTE_USER}" != "root" ]; then
            # Verify the user exists before using it
            if id -u "${_REMOTE_USER}" > /dev/null 2>&1; then
                resolved_username="${_REMOTE_USER}"
            else
                # _REMOTE_USER doesn't exist, fall through to normal detection
                resolved_username=""
            fi
        fi
        
        # If we didn't resolve via _REMOTE_USER, try to find a non-root user
        if [ -z "${resolved_username}" ]; then
            # Try to find a non-root user from a list of common usernames
            # The list includes: devcontainer, vscode, node, codespace, and the user with UID 1000
            local possible_users=("devcontainer" "vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd 2>/dev/null || echo '')")
            
            for current_user in "${possible_users[@]}"; do
                # Skip empty entries
                if [ -z "${current_user}" ]; then
                    continue
                fi
                
                # Check if user exists
                if id -u "${current_user}" > /dev/null 2>&1; then
                    resolved_username="${current_user}"
                    break
                fi
            done
            
            # If no user found, use the fallback
            if [ -z "${resolved_username}" ]; then
                resolved_username="${fallback_user}"
            fi
        fi
    elif [ "${input_username}" = "none" ]; then
        # Explicit "none" means use root
        resolved_username="root"
    else
        # Specific username provided - validate it exists
        if id -u "${input_username}" > /dev/null 2>&1; then
            resolved_username="${input_username}"
        else
            # User doesn't exist, fall back to root
            resolved_username="root"
        fi
    fi

    echo "${resolved_username}"
}
