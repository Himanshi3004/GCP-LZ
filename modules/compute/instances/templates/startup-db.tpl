#!/bin/bash
set -e

# Install Ops Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Install PostgreSQL
sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib

# Configure PostgreSQL
sudo systemctl enable postgresql
sudo systemctl start postgresql

echo "Database server setup complete"