#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/dotnet
# Maintainer: The Dev Container spec maintainers

# Removes leading and trailing whitespace from an input string
# Usage: trim_whitespace <text>
trim_whitespace() {
    text="$1"

    # Remove leading spaces
    while [ "${text:0:1}" == " " ]; do
        text="${text:1}"
    done

    # Remove trailing spaces
    while [ "${text: -1}" == " " ]; do
        text="${text:0:-1}"
    done

    echo "$text"
}

# Splits comma-separated values into an array while ignoring empty entries
# Usage: split_csv <comma-separated-values>
split_csv() {
    local -a values=()
    while IFS="," read -ra entries; do
        for entry in "${entries[@]}"; do
            entry="$(trim_whitespace "$entry")"
            if [ -n "$entry" ]; then
                values+=("$entry")
            fi
        done
    done <<< "$1"

    echo "${values[@]}"
}