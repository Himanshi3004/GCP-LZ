#!/bin/bash

set -e

echo "Starting performance tests..."

# Test Terraform plan performance
echo "Testing Terraform plan performance..."
start_time=$(date +%s)
terraform plan -out=perf-plan >/dev/null 2>&1
end_time=$(date +%s)
plan_duration=$((end_time - start_time))

echo "Plan duration: ${plan_duration}s"

if [ $plan_duration -gt 300 ]; then
    echo "FAIL: Plan took longer than 5 minutes"
    exit 1
fi

# Test module count
module_count=$(terraform show -json perf-plan | jq '.planned_values.root_module.child_modules | length')
echo "Module count: $module_count"

if [ $module_count -gt 50 ]; then
    echo "WARN: High module count may impact performance"
fi

# Test resource count
resource_count=$(terraform show -json perf-plan | jq '.planned_values.root_module | .. | objects | select(has("resources")) | .resources | length' | awk '{sum+=$1} END {print sum}')
echo "Resource count: $resource_count"

# Clean up
rm -f perf-plan

echo "Performance tests completed"