#!/bin/bash

# Error handling setup
function handle_error {
    echo "An error occurred: $1"
    exit 1
}
trap 'handle_error "Error on line $LINENO"' ERR

# https://www.elastic.co/guide/en/elastic-stack/current/installing-stack-demo-self.html

# Add repository & install elasticsearch
sudp rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat <<EOF | sudo tee /etc/yum.repos.d/elasticsearch.repo
[elasticsearch]
name=Elasticsearch repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
sudo yum install -y elasticsearch

# Set Elastic search config
sudo sed -i \
  -e 's/.*cluster.name:.*/cluster.name: pezl-cluster/' \
  -e "s/.*network.host:.*/network.host: $(hostname -I | awk {'print $1'})/" \
  -e 's/.*transport.host:.*/transport.host: 0.0.0.0/' \
  /etc/elasticsearch/elasticsearch.yml

# Start Service Elastic search
systemctl start elasticsearch.service

# When Cluster in First node
sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s node
# for Secound node
sudo /usr/share/elasticsearch/bin/elasticsearch-reconfigure-node --enrollment-token <enrollment-token>

# Generate a Kibana enrollment token
sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana