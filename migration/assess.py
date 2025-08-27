#!/usr/bin/env python3

import json
import subprocess
import sys
from datetime import datetime

class MigrationAssessment:
    def __init__(self, project_id):
        self.project_id = project_id
        self.assessment = {
            'timestamp': datetime.now().isoformat(),
            'project_id': project_id,
            'resources': {},
            'recommendations': []
        }
    
    def assess_compute_instances(self):
        """Assess compute instances for migration"""
        result = subprocess.run([
            'gcloud', 'compute', 'instances', 'list',
            '--project', self.project_id,
            '--format', 'json'
        ], capture_output=True, text=True)
        
        instances = json.loads(result.stdout)
        self.assessment['resources']['compute_instances'] = {
            'count': len(instances),
            'details': instances
        }
        
        # Add recommendations
        for instance in instances:
            if 'n1-' in instance.get('machineType', ''):
                self.assessment['recommendations'].append({
                    'type': 'compute',
                    'resource': instance['name'],
                    'recommendation': 'Upgrade to newer machine type (e2, n2)'
                })
    
    def assess_storage(self):
        """Assess storage resources"""
        result = subprocess.run([
            'gcloud', 'storage', 'buckets', 'list',
            '--project', self.project_id,
            '--format', 'json'
        ], capture_output=True, text=True)
        
        buckets = json.loads(result.stdout) if result.stdout else []
        self.assessment['resources']['storage_buckets'] = {
            'count': len(buckets),
            'details': buckets
        }
    
    def assess_databases(self):
        """Assess database instances"""
        result = subprocess.run([
            'gcloud', 'sql', 'instances', 'list',
            '--project', self.project_id,
            '--format', 'json'
        ], capture_output=True, text=True)
        
        databases = json.loads(result.stdout) if result.stdout else []
        self.assessment['resources']['sql_instances'] = {
            'count': len(databases),
            'details': databases
        }
        
        # Check for legacy versions
        for db in databases:
            version = db.get('databaseVersion', '')
            if 'MYSQL_5_6' in version or 'POSTGRES_9_6' in version:
                self.assessment['recommendations'].append({
                    'type': 'database',
                    'resource': db['name'],
                    'recommendation': 'Upgrade to supported database version'
                })
    
    def assess_networking(self):
        """Assess networking configuration"""
        # Check VPC networks
        result = subprocess.run([
            'gcloud', 'compute', 'networks', 'list',
            '--project', self.project_id,
            '--format', 'json'
        ], capture_output=True, text=True)
        
        networks = json.loads(result.stdout)
        self.assessment['resources']['networks'] = {
            'count': len(networks),
            'details': networks
        }
        
        # Check for default network
        for network in networks:
            if network['name'] == 'default':
                self.assessment['recommendations'].append({
                    'type': 'networking',
                    'resource': 'default',
                    'recommendation': 'Replace default network with custom VPC'
                })
    
    def generate_report(self):
        """Generate assessment report"""
        self.assess_compute_instances()
        self.assess_storage()
        self.assess_databases()
        self.assess_networking()
        
        # Calculate migration complexity
        total_resources = sum([
            self.assessment['resources'].get('compute_instances', {}).get('count', 0),
            self.assessment['resources'].get('storage_buckets', {}).get('count', 0),
            self.assessment['resources'].get('sql_instances', {}).get('count', 0),
            self.assessment['resources'].get('networks', {}).get('count', 0)
        ])
        
        if total_resources < 10:
            complexity = 'Low'
        elif total_resources < 50:
            complexity = 'Medium'
        else:
            complexity = 'High'
            
        self.assessment['migration_complexity'] = complexity
        self.assessment['total_resources'] = total_resources
        
        return self.assessment

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 assess.py PROJECT_ID")
        sys.exit(1)
    
    project_id = sys.argv[1]
    assessor = MigrationAssessment(project_id)
    report = assessor.generate_report()
    
    # Save report
    with open(f'assessment_{project_id}_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json', 'w') as f:
        json.dump(report, f, indent=2)
    
    print(f"Assessment completed for project: {project_id}")
    print(f"Total resources: {report['total_resources']}")
    print(f"Migration complexity: {report['migration_complexity']}")
    print(f"Recommendations: {len(report['recommendations'])}")

if __name__ == "__main__":
    main()