# Cloud Operations Module

Implements operational excellence tools including Cloud Trace, Profiler, Debugger, Error Reporting, and uptime monitoring.

## Features

- **Cloud Trace**: Distributed tracing for applications
- **Cloud Profiler**: Continuous profiling for performance optimization
- **Cloud Debugger**: Live debugging without stopping applications
- **Error Reporting**: Real-time error monitoring and alerting
- **Uptime Checks**: Synthetic monitoring for service availability

## Usage

```hcl
module "operations" {
  source = "./modules/observability/operations"
  
  project_id              = var.project_id
  region                 = var.region
  enable_trace           = true
  enable_profiler        = true
  enable_debugger        = true
  enable_error_reporting = true
  enable_uptime_checks   = true
  
  uptime_check_urls = [
    "example.com",
    "api.example.com"
  ]
  
  labels = {
    environment = "prod"
    team        = "ops"
  }
}
```

## Requirements

- Cloud Trace API enabled
- Cloud Profiler API enabled
- Cloud Debugger API enabled
- Error Reporting API enabled
- Cloud Monitoring API enabled

## Outputs

- `service_account_email`: Operations service account email
- `trace_enabled`: Cloud Trace status
- `profiler_enabled`: Cloud Profiler status
- `debugger_enabled`: Cloud Debugger status
- `error_reporting_enabled`: Error Reporting status
- `uptime_checks`: List of uptime check configurations