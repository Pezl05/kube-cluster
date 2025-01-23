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

# Initialize Master
kubeadm init --pod-network-cidr=$NETWORK_CIDR --upload-certs --control-plane-endpoint=$MASTER_ENDPOINT

# Set KUBECONFIG
mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf

# Deploy CNI
if [[ "$CNI" == "calico" ]]; then
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
else
    CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
    CLI_ARCH=amd64
    if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
    curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
    sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
    sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
    rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
    cilium install
    cilium hubble enable
fi

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm -rf get_helm.sh