#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Name of the generated script file
SCRIPT_NAME="build_and_run.sh"

# Dynamically write the script to a file
cat > $SCRIPT_NAME <<'EOF'
#!/bin/bash

# Parameters
BASE_IMAGE=${1:-"ubuntu:latest"}
IMAGE_NAME=${2:-"custom-image"}

cat > setup_history.sh <<EOL
#!/bin/sh

set -e

echo "Activating feature 'shell-history'"
echo "User: vscode     User home: /home/vscode"

echo "Creating sub-folder with random folder named python-app.."

# Create the shell history directory in the mounted volume
HISTORY_DIR=/devcontainers/python-app/shellHistory
USER_HISTORY_FILE=/home/vscode/.bash_history
VOLUME_HISTORY_FILE=/devcontainers/python-app/shellHistory/.bash_history

# Create the history directory in the volume, if it doesn’t already exist
sudo mkdir -p /devcontainers/python-app/shellHistory
sudo chown -R vscode /devcontainers/python-app/shellHistory
sudo chmod -R u+rwx /devcontainers/python-app/shellHistory

# Ensure the volume's history file exists and set permissions
sudo touch /devcontainers/python-app/shellHistory/.bash_history
sudo chown -R vscode /devcontainers/python-app/shellHistory/.bash_history
sudo chmod -R u+rwx /devcontainers/python-app/shellHistory/.bash_history

# Symlink for Bash history
sudo ln -sf /home/vscode/.bash_history /devcontainers/python-app/shellHistory/.bash_history

# Configure immediate history saving to the volume
if ! grep -q "PROMPT_COMMAND" "/home/vscode/.bashrc"; then
    echo 'PROMPT_COMMAND="history -a; history -r;"' >> "/home/vscode/.bashrc"
fi

echo "Shell history setup for history persistence amongst active containers is complete."
EOL

# Create entrypoint script
cat > entrypoint.sh <<EOL
#!/bin/bash

# Log entrypoint execution
echo "Executing entrypoint script..." > /var/log/entrypoint.log

# Execute setup history script
chmod +x /usr/local/bin/setup_history.sh >> /var/log/entrypoint.log 2>&1
/usr/local/bin/setup_history.sh >> /var/log/entrypoint.log 2>&1

# Keep the container running
tail -f /dev/null
EOL

# Create Dockerfile
cat > Dockerfile <<EOL
FROM $BASE_IMAGE
RUN apt-get update && apt-get install -y curl git sudo
COPY setup_history.sh /usr/local/bin/setup_history.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
EOL

# Build and tag the image
sudo docker build -t $IMAGE_NAME .

# Run the container again for attaching volume
CONTAINER_ID=$(sudo docker run -v devcontainers:/devcontainers -itd $IMAGE_NAME) > /dev/null

# Output the container ID to a file
echo "CONTAINER_ID=$CONTAINER_ID" > /tmp/container_id.txt

echo "Started container: $CONTAINER_ID"
EOF

# Make the generated script executable
chmod +x $SCRIPT_NAME
./$SCRIPT_NAME "mcr.microsoft.com/devcontainers/python:latest" "python-app"

# Function to add shell history
add_shell_history() {
    local container_id=$1
    local history_message=$2
    echo -e "\nWriting shell history: $history_message";
    sudo docker exec -it $container_id /bin/bash -c "echo \"$history_message\" >> ~/.bash_history"
}

# Function to check shell history
check_shell_history() {
    local container_id=$1
    echo -e "\nChecking shell history from container: ";
    sudo docker exec -it $container_id /bin/bash -c "cat ~/.bash_history"
}

source /tmp/container_id.txt

# Start the container and add shell history
sudo docker start $CONTAINER_ID > /dev/null
add_shell_history $CONTAINER_ID "Shell History for First Container Created."
sudo docker stop $CONTAINER_ID > /dev/null

# Start the container and check shell history persistence
sudo docker start $CONTAINER_ID > /dev/null
check_shell_history $CONTAINER_ID

# Report result
reportResults
