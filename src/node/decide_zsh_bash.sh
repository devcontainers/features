#!/bin/bash

if [ "$(basename "$SHELL")" = "bash" ]; then
    echo "Sourcing bash install script.."
    chmod +x ./bash_install_node.sh
    source ./bash_install_node.sh
elif [ "$(basename "$SHELL")" = "zsh" ]; then
    echo "Sourcing zsh install Script.."
    chmod +x ./zsh_install_node.zsh
    source ./zsh_install_node.zsh
else
    echo "Unknown shell"
fi