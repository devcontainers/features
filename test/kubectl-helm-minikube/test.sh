#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "kube" kubectl
check "helm" helm version
check "minikune" minikube version

# By default bash complete is disabled for the root user
# Enable it by replacing current ~/.bashrc with the /etc/skel/.bashrc file
mv ~/.bashrc ~/.bashrc.bak
cp /etc/skel/.bashrc ~/

check "helm-bash-completion-contains-version-command" ./checkBashCompletion.sh "helm " "version"

# Restore original ~/.bashrc
mv ~/.bashrc.bak ~/.bashrc

# Report result
reportResults