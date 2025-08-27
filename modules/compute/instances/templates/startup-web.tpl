#!/bin/bash
set -e

# Install Ops Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Install nginx
sudo apt-get update
sudo apt-get install -y nginx

# Configure nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Set metadata
curl -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/attributes/startup-script-status" \
  -X PUT -d "complete"

echo "Web server setup complete"