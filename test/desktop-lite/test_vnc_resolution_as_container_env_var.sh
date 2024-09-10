#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

GREEN='\033[0;32m'; NC='\033[0m'; RED='\033[0;31m'; YELLOW='\033[0;33m';

# Check if xtigervnc & noVnc processes are running after successful installation and initialization
check_process_running() {
    port=$1
    # Get process id of process running on specific port
    PID=$(lsof -i :$port | awk 'NR==2 {print $2}')
    if [ -n "$PID" ]; then
        CMD=$(ps -p $PID -o cmd --no-headers)
        echo -e "${GREEN}Command running on port $port: ${YELLOW}$CMD${NC}"
    else
        echo -e "${RED}No process found listening on port $port.${NC}"
        exit 1
    fi
}

check_w_config_resolution() {
    configResolution=$1
    actualResolution=$2

    if echo "$1" | grep -q "$2"; then 
        echo -e "\n👍👍 ${GREEN}Configured resolution i.e. ${YELLOW}$configResolution${GREEN} has been set as vnc resolution i.e. ${YELLOW}$actualResolution${GREEN} in container.${NC}"
    else 
        echo -e "\n❌❌ ${GREEN}Configured resolution i.e. ${YELLOW}$configResolution${GREEN} couldn't be set as vnc resolution i.e. ${YELLOW}$actualResolution${GREEN} in container.${NC}"
    fi
}

check "Whether xtigervnc is Running" check_process_running 5901
resolution=$(ps -x -ww | grep Xtigervnc | awk "{for(i=1;i<=NF;i++) if (\$i ~ /-geometry/) {print \$(i+1); exit}}")
check "xtigervnc resolution" bash -c '$resolution'
check_w_config_resolution $VNC_RESOLUTION $resolution 
sleep 2
check "Whether no_vnc is Running" check_process_running 6080

check "desktop-init-exists" bash -c "ls /usr/local/share/desktop-init.sh"
check "log-exists" bash -c "ls /tmp/container-init.log"
check "log file contents" bash -c "cat /tmp/container-init.log"

# Report result
reportResults