#!/bin/bash

# Error handling setup
function handle_error {
    echo "An error occurred: $1"
    exit 1
}
trap 'handle_error "Error on line $LINENO"' ERR

# Setup Cert-manager
helm repo add jetstack https://charts.jetstack.io
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.16.2 \
  --set crds.enabled=true

# Create Namespace Observability
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: observability
EOF

# Setup Jaeger Operator
kubectl create -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.62.0/jaeger-operator.yaml -n observability

# Create Jaeger
kubectl apply -f - <<EOF
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger
  namespace: observability
spec:
  strategy: all-in-one
EOF

# Patch Ingress Nginx 
kubectl patch ingress jaeger-query -n observability --type=json \
 -p='[{"op": "add", "path": "/spec/ingressClassName", "value": "nginx"}]'


















