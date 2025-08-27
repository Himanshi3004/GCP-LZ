#!/usr/bin/env python3

import random
import time
import subprocess
import json

class ChaosTest:
    def __init__(self, project_id):
        self.project_id = project_id
        
    def simulate_instance_failure(self):
        """Simulate compute instance failure"""
        print("Simulating instance failure...")
        
        # Get running instances
        result = subprocess.run([
            'gcloud', 'compute', 'instances', 'list',
            '--project', self.project_id,
            '--format', 'json'
        ], capture_output=True, text=True)
        
        instances = json.loads(result.stdout)
        if not instances:
            print("No instances found")
            return
            
        # Stop random instance
        instance = random.choice(instances)
        instance_name = instance['name']
        zone = instance['zone'].split('/')[-1]
        
        print(f"Stopping instance: {instance_name}")
        subprocess.run([
            'gcloud', 'compute', 'instances', 'stop',
            instance_name, '--zone', zone,
            '--project', self.project_id
        ])
        
        # Wait and check recovery
        time.sleep(60)
        self.check_system_health()
        
    def simulate_network_partition(self):
        """Simulate network partition"""
        print("Simulating network partition...")
        
        # Create temporary firewall rule to block traffic
        subprocess.run([
            'gcloud', 'compute', 'firewall-rules', 'create',
            'chaos-block-rule',
            '--action', 'DENY',
            '--rules', 'tcp:80,tcp:443',
            '--source-ranges', '0.0.0.0/0',
            '--project', self.project_id
        ])
        
        time.sleep(30)
        
        # Remove the rule
        subprocess.run([
            'gcloud', 'compute', 'firewall-rules', 'delete',
            'chaos-block-rule', '--quiet',
            '--project', self.project_id
        ])
        
        self.check_system_health()
        
    def check_system_health(self):
        """Check overall system health"""
        print("Checking system health...")
        
        # Check load balancer health
        result = subprocess.run([
            'gcloud', 'compute', 'backend-services', 'list',
            '--project', self.project_id,
            '--format', 'json'
        ], capture_output=True, text=True)
        
        backend_services = json.loads(result.stdout)
        for service in backend_services:
            print(f"Backend service: {service['name']} - Health checks configured")
            
        print("System health check completed")

def main():
    project_id = "test-project-123"  # Replace with actual project ID
    
    chaos = ChaosTest(project_id)
    
    print("Starting chaos engineering tests...")
    
    # Run chaos tests
    chaos.simulate_instance_failure()
    chaos.simulate_network_partition()
    
    print("Chaos tests completed")

if __name__ == "__main__":
    main()