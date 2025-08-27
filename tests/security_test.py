#!/usr/bin/env python3

import subprocess
import json
import sys

def run_tfsec():
    """Run tfsec security scanning"""
    try:
        result = subprocess.run(['tfsec', '.', '--format', 'json'], 
                              capture_output=True, text=True, cwd='../')
        return json.loads(result.stdout) if result.stdout else []
    except Exception as e:
        print(f"Error running tfsec: {e}")
        return []

def run_checkov():
    """Run checkov security scanning"""
    try:
        result = subprocess.run(['checkov', '-d', '../', '--framework', 'terraform', '-o', 'json'], 
                              capture_output=True, text=True)
        return json.loads(result.stdout) if result.stdout else {}
    except Exception as e:
        print(f"Error running checkov: {e}")
        return {}

def test_security_compliance():
    """Test security compliance across all modules"""
    print("Running security tests...")
    
    # Run tfsec
    tfsec_results = run_tfsec()
    critical_issues = [r for r in tfsec_results if r.get('severity') == 'CRITICAL']
    
    if critical_issues:
        print(f"FAIL: {len(critical_issues)} critical security issues found")
        for issue in critical_issues:
            print(f"  - {issue.get('rule_description', 'Unknown issue')}")
        return False
    
    # Run checkov
    checkov_results = run_checkov()
    failed_checks = checkov_results.get('results', {}).get('failed_checks', [])
    
    if failed_checks:
        print(f"FAIL: {len(failed_checks)} checkov security checks failed")
        return False
    
    print("PASS: All security tests passed")
    return True

if __name__ == "__main__":
    success = test_security_compliance()
    sys.exit(0 if success else 1)