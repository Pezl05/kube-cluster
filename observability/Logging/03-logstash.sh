#!/bin/bash

# Error handling setup
function handle_error {
    echo "An error occurred: $1"
    exit 1
}
trap 'handle_error "Error on line $LINENO"' ERR

# https://www.elastic.co/guide/en/logstash/current/setup-logstash.html

# Install JAVA
yum install java-11-openjdk-devel

# Add repository & install logstash
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat <<EOF | sudo tee /etc/yum.repos.d/logstash.repo
[logstash-8.x]
name=Elastic repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
sudo yum install logstash

# Set Log stash config
sudo sed -i -e "s/.*node.name:.*/node.name: $(hostname)/" /etc/logstash/logstash.yml

# Config Pipeline
cat <<EOF | sudo tee /etc/logstash/conf.d/logstash.conf
input {
  beats {
    port => 5044
  }
}
filter {
  grok {
    match => { "message" => "%{TIMESTAMP_ISO8601:timestamp} \[%{LOGLEVEL:level}\] \[%{DATA:class}\] - %{GREEDYDATA:msg}" }
  }
}
output {
  elasticsearch {
    index => "logstash-%{[@metadata][beat]}"
    hosts => [ "https://192.168.100.100:9200" ]
    user => "elastic"
    password => "EItV0vonMoBWBnAljjJp"
    ssl_certificate_authorities => "/etc/logstash/certs/http_ca.crt"
  }
}
EOF