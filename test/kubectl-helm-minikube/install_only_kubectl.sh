#!/bin/bash
set -e

# Optional: Import test library
source dev-container-features-test-lib

set +e
    kubectl
    exit_code=$?
    check "kubectl-is-not-installed" bash -c "echo ${exit_code} | grep 127"

    helm version
    exit_code=$?
    check "helm-is-not-installed" bash -c "echo ${exit_code} | grep 127"

    minikube version
    exit_code=$?
    check "minikube is-not-installed" bash -c "echo ${exit_code} | grep 127"
set -e

# Report result
reportResults
