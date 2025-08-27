# CI/CD Pipeline Module

Implements automated CI/CD pipelines with Cloud Build, Cloud Deploy, testing stages, approval workflows, and rollback mechanisms for reliable application deployment.

## Features

- **Cloud Build Pipelines**: Automated build and test pipelines with Docker support
- **Cloud Deploy**: Multi-environment deployment automation with approval gates
- **Testing Stages**: Unit, integration, and end-to-end testing automation
- **Approval Workflows**: Manual approval requirements for production deployments
- **Rollback Mechanisms**: Automatic rollback on deployment failures
- **Monitoring**: Deployment health monitoring and failure alerts

## Usage

```hcl
module "cicd_pipeline" {
  source = "./modules/devops/cicd-pipeline"
  
  project_id = var.project_id
  region     = var.region
  
  pipelines = {
    "web-app" = {
      source_repo    = "applications"
      target_service = "web-app"
      environments   = ["dev", "staging", "prod"]
      build_config   = "cloudbuild.yaml"
      test_commands  = ["npm test", "npm run e2e"]
    }
    "api-service" = {
      source_repo    = "api-backend"
      target_service = "api-service"
      environments   = ["dev", "prod"]
      build_config   = "cloudbuild.yaml"
      test_commands  = ["go test ./...", "go run integration_test.go"]
    }
  }
  
  approval_required = ["prod"]
  enable_rollback   = true
  
  notification_channels = [
    "projects/my-project/notificationChannels/123456789"
  ]
  
  labels = {
    environment = "prod"
    team        = "devops"
  }
}
```

## Requirements

- Cloud Build API enabled
- Cloud Deploy API enabled
- Container Registry API enabled
- Cloud Run API enabled
- Cloud Functions API enabled
- Source repositories configured

## Outputs

- `ci_pipeline_triggers`: CI pipeline trigger IDs
- `test_pipeline_triggers`: Test pipeline trigger IDs
- `delivery_pipelines`: Cloud Deploy delivery pipeline names
- `deployment_targets`: Cloud Deploy target names
- `cloud_run_services`: Cloud Run service URLs
- `rollback_trigger_id`: Rollback trigger ID
- `pubsub_topics`: Pub/Sub topic names
- `build_artifacts_bucket`: Build artifacts bucket name
- `service_account_email`: CI/CD pipeline service account email