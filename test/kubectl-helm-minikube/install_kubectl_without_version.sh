#!/bin/bash
set -e

# Optional: Import test library
source dev-container-features-test-lib

# Define expected versions
KUBECTL_EXPECTED_VERSION="1.30"
HELM_VERSION="3.16"
MINIKUBE_VERSION="1.28"

set +e
    kubectl version --client --output json | jq -r '.clientVersion.gitVersion' | grep "${KUBECTL_VERSION}"
    exit_code=$?
    check "kubectl-version-${KUBECTL_VERSION}-installed" bash -c "echo ${exit_code} | grep 0"
    echo "kubectl version:"
    kubectl version --client 

    helm version --short | grep "${HELM_VERSION}"
    exit_code=$?
    check "helm-version-${HELM_VERSION}-installed" bash -c "echo ${exit_code} | grep 0"
    echo "helm version:"
    helm version --short

    minikube version --short | grep "${MINIKUBE_VERSION}"  
    exit_code=$?
    check "minikube-version-${MINIKUBE_VERSION}-installed" bash -c "echo ${exit_code} | grep 0"
    echo "minikube version:"
    minikube version --short
set -e

# Report result
reportResults