#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Initialize an array to store container IDs
declare -a CONTAINER_IDS

# Name of the generated script file
SCRIPT_NAME="build_and_run.sh"

# Dynamically write the script to a file
cat > $SCRIPT_NAME <<'EOF'
#!/bin/bash

# Parameters
BASE_IMAGE=${1:-"ubuntu:latest"}
IMAGE_NAME=${2:-"custom-image"}

# Create Dockerfile
cat > Dockerfile <<EOL
FROM $BASE_IMAGE
RUN apt-get update && apt-get install -y curl git sudo
RUN useradd -m vscode
CMD ["bash"]
EOL

# Build and tag the image
docker build -t $IMAGE_NAME .

# Run the container in the background
CONTAINER_ID=$(docker run -it -d $IMAGE_NAME)
echo "Started container: $CONTAINER_ID"


# Copy the setup_history.sh file to the running container
sudo docker cp /etc/env.sh $CONTAINER_ID:/etc/env.sh
sudo docker cp /etc/setup_history.sh $CONTAINER_ID:/etc/setup_history.sh


# Execute the command inside the container to set the environment variable and run the script
docker exec -it $CONTAINER_ID bash -c "chmod +x /etc/setup_history.sh && export DEVCONTAINER_ID=${IMAGE_NAME} && . /etc/setup_history.sh"

docker logs $CONTAINER_ID
EOF

# Make the generated script executable
chmod +x $SCRIPT_NAME

echo "The script '$SCRIPT_NAME' has been created. You can execute it with parameters like:"
echo "./$SCRIPT_NAME python python-app"

./$SCRIPT_NAME python python-app
./$SCRIPT_NAME node node-app

# Run the first container (python-app)
CONTAINER_ID_PYTHON=$(docker run -it -d python-app)
CONTAINER_IDS+=("$CONTAINER_ID_PYTHON")
echo "Started python-app container: $CONTAINER_ID_PYTHON"

# Run the second container (node-app)
CONTAINER_ID_NODE=$(docker run -it -d node-app)
CONTAINER_IDS+=("$CONTAINER_ID_NODE")
echo "Started node-app container: $CONTAINER_ID_NODE"

# Export the container ID array to a file for use outside
export CONTAINER_IDS_STR="${CONTAINER_IDS[*]}"

echo "Container IDs: $CONTAINER_IDS_STR"

container1=${CONTAINER_IDS[0]}
container2=${CONTAINER_IDS[1]}

# Function to add shell history
add_shell_history() {
    local container_id=$1
    local history_message=$2
    docker exec -it $container_id /bin/bash -c "echo \"$history_message\" >> ~/.bash_history"
}

# Function to check shell history
check_shell_history() {
    local container_id=$1
    docker exec -it $container_id /bin/bash -c "cat ~/.bash_history"
}

# Start the first container and add shell history
docker start $container1
add_shell_history $container1 "First container shell history"
docker stop $container1

# Start the second container and add shell history
docker start $container2
add_shell_history $container2 "Second container shell history"
docker stop $container2

# Start both containers and check shell history persistence
docker start $container1
echo "Shell history for container 1:"
check_shell_history $container1
docker stop $container1

docker start $container2
echo "Shell history for container 2:"
check_shell_history $container2
docker stop $container2

# Report result
reportResults
