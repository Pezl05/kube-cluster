#!/bin/bash

# Error handling setup
function handle_error {
    echo "An error occurred: $1"
    exit 1
}
trap 'handle_error "Error on line $LINENO"' ERR

# Setup Ingress Nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/cloud/deploy.yaml

# Create TLS secret
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: project-mgmt-tls
  namespace: project-mgmt
type: kubernetes.io/tls
data:
  tls.crt: $(cat pezl-sw.crt | base64 | tr -d '\n')
  tls.key: $(cat pezl-sw.key | base64 | tr -d '\n')
EOF

# Patch Ingress Nginx to NodePort
kubectl patch svc ingress-nginx-controller -n ingress-nginx \
  -p '{"spec": {"type": "NodePort"}}'

# Create Create
kubectl apply -f registry.yaml

# Deploy Go Authentication Service
kubectl apply -f auth-cd.yaml

# Deploy NestJS Project Service
kubectl apply -f project-cd.yaml

# Deploy Python Task Service
kubectl apply -f task-cd.yaml

# Deploy NextJS Front-End Service
kubectl apply -f front-cd.yaml 

kubectl get po,svc,ingress -n ingress-nginx 

echo "Command change service ingress-nginx to NodePort"
echo "kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec": {"type": "NodePort"}}'"
echo "kubectl get po,svc,ingress -n ingress-nginx