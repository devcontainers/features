#!/bin/bash

# Run PowerShell command to check installation
pwsh --version &> /dev/null

# Check if the command was successful
if [ $? -eq 0 ]; then
    echo "PowerShell is installed."
else
    echo "PowerShell is not installed."
    exit 1
fi