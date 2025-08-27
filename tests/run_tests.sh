#!/bin/bash

set -e

echo "=== GCP Landing Zone Integration Tests ==="

# Set test environment variables
export TF_VAR_project_id="test-project-123"
export TF_VAR_organization_id="123456789012"
export TF_VAR_billing_account="ABCDEF-123456-GHIJKL"
export TF_VAR_environment="test"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Run Terraform validation
echo "Running Terraform validation..."
terraform validate

# Run security tests
echo "Running security tests..."
python3 security_test.py

# Run performance tests
echo "Running performance tests..."
bash performance_test.sh

# Run integration tests
echo "Running integration tests..."
cd integration
go test -v -timeout 30m
cd ..

# Run chaos tests (optional)
if [ "$RUN_CHAOS_TESTS" = "true" ]; then
    echo "Running chaos tests..."
    python3 chaos_test.py
fi

echo "All tests completed successfully!"