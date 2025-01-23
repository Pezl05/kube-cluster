#!/bin/bash

# Error handling setup
function handle_error {
    echo "An error occurred: $1"
    exit 1
}
trap 'handle_error "Error on line $LINENO"' ERR

# Create Namespace ArgoCD
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
EOF

# Setup ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Create ArgoCD External Service
kubectl expose -n argocd svc argocd-server --port=443 --target-port=8080 --name=argocd-server-external --type=NodePort
NODEPORT=$(kubectl get -n argocd svc argocd-server-external -o=jsonpath='{.spec.ports[0].nodePort}')

# Install Argo Command
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm -rf argocd-linux-amd64

# Argo Info
echo "Info for Login ArgoCD"
echo "URL: https://$(hostname -i):$NODEPORT"
echo "User: admin"
echo "Passwrod: \$ kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"