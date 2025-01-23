#!/bin/bash

# Error handling setup
function handle_error {
    echo "An error occurred: $1"
    exit 1
}
trap 'handle_error "Error on line $LINENO"' ERR

# https://www.elastic.co/guide/en/elastic-stack/current/installing-stack-demo-self.html

# Add repository & install kibana
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat <<EOF | sudo tee /etc/yum.repos.d/kibana.repo
[kibana-8.x]
name=Kibana repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
sudo yum install -y kibana

# Set Kibana search config
sudo sed -i \
    -e "s/.*server.host:.*/server.host: $(hostname -I | awk {'print $1'})/" \
    -e 's/.*elasticsearch.hosts:.*/elasticsearch.hosts: ["https://192.168.100.100:9200"]/' \
    -e 's/.*elasticsearch.ssl.verificationMode:.*/elasticsearch.ssl.verificationMode: none/' \
    -e 's/.*elasticsearch.ssl.certificateAuthorities:.*/elasticsearch.ssl.certificateAuthorities: ["/etc/kibana/certs/http_ca.crt"]/' \
    -e 's/.*elasticsearch.serviceAccountToken:.*/elasticsearch.serviceAccountToken: "AAEAAWVsYXN0aWMva2liYW5hL2Vucm9sbC1wcm9jZXNzLXRva2VuLTE3MzY0Mjg5NTczMzE6Smg4WnJSOGdSQU9kLWhHMmowdGRDdw"/' \
    /etc/kibana/kibana.yml

# Start Service Kibana & Get Token from Elastic search first node
systemctl start kibana.service