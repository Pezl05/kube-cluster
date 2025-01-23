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

# Disable firewall
systemctl disable firewalld.service --now

# Install essential tools
yum install -y bash-completion nc vim net-tools yum-utils device-mapper-persistent-data lvm2

# Load required kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/kubernetes.conf
overlay
br_netfilter
EOF
modprobe br_netfilter
modprobe overlay

# Configure sysctl for Kubernetes networking
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# Disable swap
sed -i '/swap/d' /etc/fstab
sudo swapoff -a

if [[ "$RUNTIME" == "crio" ]]; then
    echo "Installing CRI-O..."
    ./runtime-crio.sh
else
    echo "Installing Container-D..."
    ./runtime-containerd.sh
fi

# Add Kubernetes repository
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/rpm/repodata/repomd.xml.key
EOF

# Install Kubernetes components
yum install -y container-selinux kubelet kubeadm kubectl

# Enable and start kubelet
sudo systemctl daemon-reload
sudo systemctl enable kubelet --now

# Configure kubectl auto-completion and alias
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
sudo chmod a+r /etc/bash_completion.d/kubectl
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
source ~/.bashrc