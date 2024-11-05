#!/bin/bash

# Source the environment variables from env.sh
if [ -f /tmp/env.sh ]; then
    . /tmp/env.sh
else
    echo "env.sh not found!"
fi

if [ "${ALLOW_SHELL_HISTORY}" = "true" ]; then
    echo "Activating feature 'shell-history'"
    echo "User: ${USERNAME}     User home: ${user_home}"

    # Create the shell history directory in the mounted volume
    HISTORY_DIR="/devcontainers/${DEVCONTAINER_ID}/shellHistory"
    USER_HISTORY_FILE="${user_home}/.bash_history"
    VOLUME_HISTORY_FILE="${HISTORY_DIR}/.bash_history"

    # Create the history directory in the volume, if it doesn’t already exist
    sudo mkdir -p "${HISTORY_DIR}"
    sudo chown -R "${USERNAME}" "${HISTORY_DIR}"
    sudo chmod -R u+rwx "${HISTORY_DIR}"

    # Ensure the volume's history file exists and set permissions
    sudo touch "${VOLUME_HISTORY_FILE}"
    sudo chown -R "${USERNAME}" "${VOLUME_HISTORY_FILE}"
    sudo chmod -R u+rwx "${VOLUME_HISTORY_FILE}"

    # Symlink for Bash history
    sudo ln -sf ${USER_HISTORY_FILE} ${VOLUME_HISTORY_FILE}

    # Configure immediate history saving to the volume
    echo 'PROMPT_COMMAND="history -a; history -r;"' >> "${user_home}/.bashrc"

    echo "Shell history setup for persistent appending is complete."
fi