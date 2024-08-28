#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/aws-cli
# Maintainer: The Dev Container spec maintainers
#
# Run this script to replace aws_bash_completer and aws_zsh_completer.sh with the latest and greatest available version
# 
COMPLETER_SCRIPTS=$(dirname "${BASH_SOURCE[0]}")
BASH_COMPLETER_SCRIPT="$COMPLETER_SCRIPTS/vendor/aws_bash_completer"
ZSH_COMPLETER_SCRIPT="$COMPLETER_SCRIPTS/vendor/aws_zsh_completer.sh"

wget https://raw.githubusercontent.com/aws/aws-cli/v2/bin/aws_bash_completer -O "$BASH_COMPLETER_SCRIPT"
chmod +x "$BASH_COMPLETER_SCRIPT"

wget https://raw.githubusercontent.com/aws/aws-cli/v2/bin/aws_zsh_completer.sh -O "$ZSH_COMPLETER_SCRIPT"
chmod +x "$ZSH_COMPLETER_SCRIPT"
