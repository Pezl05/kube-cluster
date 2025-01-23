#!/bin/bash

# Error handling setup
function handle_error {
    echo "An error occurred: $1"
    exit 1
}
trap 'handle_error "Error on line $LINENO"' ERR

# Create Namespace project-mgmt
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: project-mgmt
EOF

# Deploy Postgres Database
kubectl apply -f postgres-pvc.yaml -n project-mgmt
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install psql-mgmt bitnami/postgresql -f helm-vaule.yaml -n project-mgmt
