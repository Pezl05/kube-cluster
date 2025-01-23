#!/bin/bash

# Error handling setup
function handle_error {
    echo "An error occurred: $1"
    exit 1
}
trap 'handle_error "Error on line $LINENO"' ERR

# Setup prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack --create-namespace --namespace observability

# Change bind metrics address
sed -i "s|127.0.0.1|$(hostname -i)|" /etc/kubernetes/manifests/kube-controller-manager.yaml
sed -i "s|127.0.0.1|$(hostname -i)|" /etc/kubernetes/manifests/kube-scheduler.yaml
sed -i "s|http://127.0.0.1:2381|http://127.0.0.1:2381,http://$(hostname -i):2381|" /etc/kubernetes/manifests/kube-scheduler.yaml
kubectl get configmap -n kube-system kube-proxy -o yaml | sed "s/metricsBindAddress: ""/metricsBindAddress: "0.0.0.0:10249"/" | kubectl apply -f -
kubectl rollout restart daemonset kube-proxy -n kube-system
systemctl restart kubelet.service crio.service 

# Expose Service Prometheus UI
kubectl expose service prometheus-operated --namespace observability --type=NodePort --target-port=9090 --name=prometheus-operated-external

# Expose Service Grafana
kubectl expose service prometheus-grafana --namespace observability --type=NodePort --target-port=3000 --name=prometheus-grafana-external

# Monitoring Info
echo "### Expose Prometheus Service" 
echo "kubectl expose service prometheus-operated --namespace observability --type=NodePort --target-port=9090 --name=prometheus-operated-external"
echo "kubectl get -n observability svc prometheus-operated-external -o=jsonpath='{.spec.ports[0].nodePort}'"
echo ""
echo "### Expose Grafana Service" 
echo "kubectl expose service prometheus-grafana --namespace observability --type=NodePort --target-port=3000 --name=prometheus-grafana-external"
echo "kubectl get -n observability svc prometheus-grafana-external -o=jsonpath='{.spec.ports[0].nodePort}'"
echo ""
echo "### Password Grafana admin"
echo "kubectl get secrets -n observability prometheus-grafana -o=jsonpath='{.data.admin-password}' | base64 -d"