#!/bin/bash
set -e

# Optional: Import test library
source dev-container-features-test-lib

set +e
    kubectl
    exit_code=$?
    check "kubectl-is-installed" bash -c "echo ${exit_code} | grep 0"
    echo "kubectl version:"
    kubectl version --client 

    helm version
    exit_code=$?
    check "helm-is-installed" bash -c "echo ${exit_code} | grep 0"
    echo "helm version:"
    helm version 

    minikube version
    exit_code=$?
    check "minikube-is-installed" bash -c "echo ${exit_code} | grep 0"
    echo "minikube version:"
    minikube version
set -e

# Report result
reportResults