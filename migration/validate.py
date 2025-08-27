#!/usr/bin/env python3

import subprocess
import json
import sys
import time

class MigrationValidator:
    def __init__(self, project_id):
        self.project_id = project_id
        self.validation_results = []
    
    def validate_terraform_state(self):
        """Validate Terraform state consistency"""
        try:
            result = subprocess.run(['terraform', 'plan', '-detailed-exitcode'], 
                                  capture_output=True, text=True)
            
            if result.returncode == 0:
                self.validation_results.append({
                    'check': 'Terraform State',
                    'status': 'PASS',
                    'message': 'No changes detected'
                })
            else:
                self.validation_results.append({
                    'check': 'Terraform State',
                    'status': 'FAIL',
                    'message': 'Terraform plan shows changes'
                })
        except Exception as e:
            self.validation_results.append({
                'check': 'Terraform State',
                'status': 'ERROR',
                'message': str(e)
            })
    
    def validate_networking(self):
        """Validate networking configuration"""
        try:
            # Check VPC networks
            result = subprocess.run([
                'gcloud', 'compute', 'networks', 'list',
                '--project', self.project_id,
                '--format', 'json'
            ], capture_output=True, text=True)
            
            networks = json.loads(result.stdout)
            
            if networks:
                self.validation_results.append({
                    'check': 'VPC Networks',
                    'status': 'PASS',
                    'message': f'Found {len(networks)} networks'
                })
            else:
                self.validation_results.append({
                    'check': 'VPC Networks',
                    'status': 'FAIL',
                    'message': 'No networks found'
                })
                
        except Exception as e:
            self.validation_results.append({
                'check': 'VPC Networks',
                'status': 'ERROR',
                'message': str(e)
            })
    
    def validate_iam(self):
        """Validate IAM configuration"""
        try:
            result = subprocess.run([
                'gcloud', 'projects', 'get-iam-policy', self.project_id,
                '--format', 'json'
            ], capture_output=True, text=True)
            
            policy = json.loads(result.stdout)
            bindings = policy.get('bindings', [])
            
            if bindings:
                self.validation_results.append({
                    'check': 'IAM Policies',
                    'status': 'PASS',
                    'message': f'Found {len(bindings)} IAM bindings'
                })
            else:
                self.validation_results.append({
                    'check': 'IAM Policies',
                    'status': 'FAIL',
                    'message': 'No IAM bindings found'
                })
                
        except Exception as e:
            self.validation_results.append({
                'check': 'IAM Policies',
                'status': 'ERROR',
                'message': str(e)
            })
    
    def validate_monitoring(self):
        """Validate monitoring setup"""
        try:
            result = subprocess.run([
                'gcloud', 'logging', 'sinks', 'list',
                '--project', self.project_id,
                '--format', 'json'
            ], capture_output=True, text=True)
            
            sinks = json.loads(result.stdout) if result.stdout else []
            
            if sinks:
                self.validation_results.append({
                    'check': 'Logging Sinks',
                    'status': 'PASS',
                    'message': f'Found {len(sinks)} log sinks'
                })
            else:
                self.validation_results.append({
                    'check': 'Logging Sinks',
                    'status': 'WARN',
                    'message': 'No log sinks configured'
                })
                
        except Exception as e:
            self.validation_results.append({
                'check': 'Logging Sinks',
                'status': 'ERROR',
                'message': str(e)
            })
    
    def validate_security(self):
        """Validate security configuration"""
        try:
            # Check KMS keys
            result = subprocess.run([
                'gcloud', 'kms', 'keyrings', 'list',
                '--location', 'global',
                '--project', self.project_id,
                '--format', 'json'
            ], capture_output=True, text=True)
            
            keyrings = json.loads(result.stdout) if result.stdout else []
            
            if keyrings:
                self.validation_results.append({
                    'check': 'KMS Keyrings',
                    'status': 'PASS',
                    'message': f'Found {len(keyrings)} KMS keyrings'
                })
            else:
                self.validation_results.append({
                    'check': 'KMS Keyrings',
                    'status': 'WARN',
                    'message': 'No KMS keyrings found'
                })
                
        except Exception as e:
            self.validation_results.append({
                'check': 'KMS Keyrings',
                'status': 'ERROR',
                'message': str(e)
            })
    
    def run_validation(self):
        """Run all validation checks"""
        print(f"Running validation for project: {self.project_id}")
        
        self.validate_terraform_state()
        self.validate_networking()
        self.validate_iam()
        self.validate_monitoring()
        self.validate_security()
        
        # Print results
        print("\nValidation Results:")
        print("-" * 50)
        
        passed = 0
        failed = 0
        warnings = 0
        errors = 0
        
        for result in self.validation_results:
            status = result['status']
            if status == 'PASS':
                passed += 1
                print(f"✅ {result['check']}: {result['message']}")
            elif status == 'FAIL':
                failed += 1
                print(f"❌ {result['check']}: {result['message']}")
            elif status == 'WARN':
                warnings += 1
                print(f"WARNING  {result['check']}: {result['message']}")
            elif status == 'ERROR':
                errors += 1
                print(f"ERROR {result['check']}: {result['message']}")
        
        print("-" * 50)
        print(f"Summary: {passed} passed, {failed} failed, {warnings} warnings, {errors} errors")
        
        return failed == 0 and errors == 0

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 validate.py PROJECT_ID")
        sys.exit(1)
    
    project_id = sys.argv[1]
    validator = MigrationValidator(project_id)
    
    success = validator.run_validation()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()