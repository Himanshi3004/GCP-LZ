# Source Code Management Module

Implements source code management setup with Cloud Source Repositories, GitHub integration, branch protection policies, automated code review, and security scanning.

## Features

- **Cloud Source Repositories**: Git repositories with Pub/Sub integration
- **GitHub Integration**: Automated triggers for PR and push events
- **Branch Protection**: Configurable protection rules for critical branches
- **Code Review Policies**: Automated code quality checks and linting
- **Security Scanning**: Vulnerability scanning with Trivy and Cloud Code Analysis
- **Webhook Management**: Secure webhook handling with Secret Manager

## Usage

```hcl
module "source_management" {
  source = "./modules/devops/source-management"
  
  project_id = var.project_id
  
  repositories = {
    "landing-zone" = {
      description = "GCP Landing Zone Infrastructure"
    }
    "applications" = {
      description = "Application source code"
    }
  }
  
  enable_github_integration = true
  github_config = {
    owner           = "your-org"
    installation_id = 12345678
    app_id         = 87654321
  }
  
  branch_protection_rules = {
    "main" = {
      pattern                = "main"
      required_status_checks = ["security-scan", "terraform-validate"]
      require_code_review    = true
      dismiss_stale_reviews  = true
      require_up_to_date     = true
    }
  }
  
  labels = {
    environment = "prod"
    team        = "devops"
  }
}
```

## Requirements

- Cloud Source Repositories API enabled
- Cloud Build API enabled
- Container Analysis API enabled
- GitHub App configured (for GitHub integration)
- Secret Manager API enabled

## Outputs

- `repository_urls`: URLs of created repositories
- `github_triggers`: GitHub integration trigger IDs
- `security_scan_triggers`: Security scan trigger IDs
- `code_review_triggers`: Code review trigger IDs
- `branch_protection_triggers`: Branch protection trigger IDs
- `pubsub_topics`: Pub/Sub topic names
- `service_account_email`: Source management service account email