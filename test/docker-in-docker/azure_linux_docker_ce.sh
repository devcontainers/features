#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

echo "=== Azure Linux Docker CE Test ==="

echo "1. Verifying OS identification..."
cat /etc/os-release | grep -i azure

echo "2. Checking Docker installation..."
docker --version || {
    echo "ERROR: Docker is not installed"
    exit 1
}

echo "3. Checking if Docker binaries exist..."
which dockerd || echo "dockerd not in PATH"
ls -la /usr/bin/docker* || echo "No docker binaries in /usr/bin"
ls -la /usr/local/bin/docker* || echo "No docker binaries in /usr/local/bin"

echo "4. Checking Docker service files..."
ls -la /etc/systemd/system/docker* || echo "No systemd docker files"
ls -la /usr/lib/systemd/system/docker* || echo "No system docker service files"

echo "6. Checking Docker daemon status..."
if ! docker info >/dev/null 2>&1; then
    echo "Docker daemon not running, starting it..."
    
    # Check if docker-init script exists
    if [ -f "/usr/local/share/docker-init.sh" ]; then
        echo "Starting Docker using docker-init.sh..."
        
        # Clear any existing log
        rm -f /tmp/dockerd.log
        
        # Start docker-init in background
        nohup /usr/local/share/docker-init.sh > /tmp/docker-init.log 2>&1 &
        
        # Wait for Docker to start with better debugging
        echo "Waiting for Docker daemon to start..."
        for i in {1..30}; do
            if docker info >/dev/null 2>&1; then
                echo "Docker daemon started successfully"
                break
            fi
            echo "Waiting... ($i/30)"
            
            # Show dockerd logs if available
            if [ -f "/tmp/dockerd.log" ]; then
                echo "--- Recent dockerd.log entries ---"
                tail -5 /tmp/dockerd.log || echo "Could not read dockerd.log"
                echo "--- End of dockerd.log ---"
            fi
            
            sleep 2
        done
        
        # Final check with detailed error reporting
        if ! docker info >/dev/null 2>&1; then
            echo "ERROR: Docker daemon failed to start after 60 seconds"
            echo ""
            echo "=== DEBUGGING INFORMATION ==="
            echo ""
            echo "1. Docker init log:"
            cat /tmp/docker-init.log 2>/dev/null || echo "No docker-init.log found"
            echo ""
            echo "2. Docker daemon log:"
            cat /tmp/dockerd.log 2>/dev/null || echo "No dockerd.log found"
            echo ""
            echo "3. Process list:"
            ps aux | grep -E "(docker|containerd)" | grep -v grep || echo "No docker/containerd processes found"
            echo ""
            echo "4. Network interfaces:"
            ip addr show || ifconfig || echo "Could not get network info"
            echo ""
            echo "5. Mount points:"
            mount | grep -E "(docker|container)" || echo "No docker-related mounts"
            echo ""
            echo "6. SELinux status:"
            if command -v getenforce >/dev/null 2>&1; then
                getenforce || echo "SELinux command failed"
            else
                echo "SELinux tools not available"
            fi
            echo ""
            echo "7. Available storage:"
            df -h /var/lib/docker 2>/dev/null || df -h / || echo "Could not check storage"
            echo ""
            echo "8. System resources:"
            free -h || echo "Could not check memory"
            echo ""
            echo "=== END DEBUGGING ==="
            exit 1
        fi
    else
        echo "ERROR: docker-init.sh not found at /usr/local/share/docker-init.sh"
        ls -la /usr/local/share/ || echo "Could not list /usr/local/share/"
        exit 1
    fi
else
    echo "Docker daemon is already running"
fi

echo "7. Testing basic Docker functionality..."
docker info | head -10

echo "8. Testing container execution..."
docker run --rm alpine echo "Basic container test successful"

echo "=== Docker CE test completed successfully ==="