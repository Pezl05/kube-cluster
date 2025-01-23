#!/bin/bash

# Load Kubernetes configuration
source kubernetes.conf
set -e  

# Error handling setup
function handle_error {
    echo "An error occurred: $1"
    exit 1
}
trap 'handle_error "Error on line $LINENO"' ERR

# Get command for join Control Plane Node
echo "Command for Control Plane Node"
kubeadm token create --print-join-command --certificate-key $(kubeadm init phase upload-certs --upload-certs | tail -n1)
echo ""

# Get command for join Worker Node
echo "Command for Worker Node"
kubeadm token create --print-join-command 