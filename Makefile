# GCP Landing Zone Makefile
# Simplifies common Terraform operations across environments

.PHONY: help init plan apply destroy validate format security cost clean

# Default environment
ENV ?= dev

# Colors for output
RED    := \033[31m
GREEN  := \033[32m
YELLOW := \033[33m
BLUE   := \033[34m
RESET  := \033[0m

help: ## Show this help message
	@echo "$(BLUE)GCP Landing Zone - Available Commands$(RESET)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Usage Examples:$(RESET)"
	@echo "  make init ENV=dev     # Initialize development environment"
	@echo "  make plan ENV=staging # Plan staging deployment"
	@echo "  make apply ENV=prod   # Apply production changes"

init: ## Initialize Terraform for specified environment
	@echo "$(BLUE)Initializing Terraform for $(ENV) environment...$(RESET)"
	@cp environments/$(ENV)/backend.tf .
	@cp environments/$(ENV)/terraform.tfvars .
	@terraform init -reconfigure
	@echo "$(GREEN)✓ Terraform initialized for $(ENV)$(RESET)"

plan: ## Create Terraform execution plan
	@echo "$(BLUE)Creating execution plan for $(ENV) environment...$(RESET)"
	@terraform plan -var-file=environments/$(ENV)/terraform.tfvars
	@echo "$(GREEN)✓ Plan completed$(RESET)"

apply: ## Apply Terraform configuration
	@echo "$(BLUE)Applying Terraform configuration for $(ENV) environment...$(RESET)"
	@terraform apply -var-file=environments/$(ENV)/terraform.tfvars
	@echo "$(GREEN)✓ Apply completed$(RESET)"

destroy: ## Destroy Terraform-managed infrastructure
	@echo "$(RED)⚠️  WARNING: This will destroy all infrastructure in $(ENV) environment!$(RESET)"
	@read -p "Are you sure? Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ]
	@terraform destroy -var-file=environments/$(ENV)/terraform.tfvars
	@echo "$(RED)✓ Infrastructure destroyed$(RESET)"

validate: ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(RESET)"
	@terraform validate
	@echo "$(GREEN)✓ Configuration is valid$(RESET)"

format: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(RESET)"
	@terraform fmt -recursive
	@echo "$(GREEN)✓ Files formatted$(RESET)"

security: ## Run security scan (requires tfsec)
	@echo "$(BLUE)Running security scan...$(RESET)"
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec .; \
		echo "$(GREEN)✓ Security scan completed$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️  tfsec not installed. Install with: go install github.com/aquasecurity/tfsec/cmd/tfsec@latest$(RESET)"; \
	fi

cost: ## Estimate costs (requires infracost)
	@echo "$(BLUE)Estimating costs for $(ENV) environment...$(RESET)"
	@if command -v infracost >/dev/null 2>&1; then \
		infracost breakdown --path . --terraform-var-file=environments/$(ENV)/terraform.tfvars; \
		echo "$(GREEN)✓ Cost estimation completed$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️  infracost not installed. See: https://www.infracost.io/docs/$(RESET)"; \
	fi

clean: ## Clean temporary files
	@echo "$(BLUE)Cleaning temporary files...$(RESET)"
	@rm -f backend.tf terraform.tfvars
	@rm -rf .terraform/
	@rm -f .terraform.lock.hcl
	@rm -f terraform.tfstate*
	@echo "$(GREEN)✓ Cleanup completed$(RESET)"

bootstrap: ## Bootstrap state buckets (run once per organization)
	@echo "$(BLUE)Bootstrapping Terraform state buckets...$(RESET)"
	@echo "$(YELLOW)Creating GCS buckets for Terraform state...$(RESET)"
	@gsutil mb gs://netskope-terraform-state-dev || true
	@gsutil mb gs://netskope-terraform-state-staging || true
	@gsutil mb gs://netskope-terraform-state-prod || true
	@echo "$(YELLOW)Enabling versioning on state buckets...$(RESET)"
	@gsutil versioning set on gs://netskope-terraform-state-dev
	@gsutil versioning set on gs://netskope-terraform-state-staging
	@gsutil versioning set on gs://netskope-terraform-state-prod
	@echo "$(GREEN)✓ Bootstrap completed$(RESET)"

check-env: ## Check if environment is valid
	@if [ "$(ENV)" != "dev" ] && [ "$(ENV)" != "staging" ] && [ "$(ENV)" != "prod" ]; then \
		echo "$(RED)Error: ENV must be one of: dev, staging, prod$(RESET)"; \
		exit 1; \
	fi

# Environment-specific shortcuts
dev: ## Quick deploy to development
	@$(MAKE) init ENV=dev
	@$(MAKE) plan ENV=dev
	@$(MAKE) apply ENV=dev

staging: ## Quick deploy to staging
	@$(MAKE) init ENV=staging
	@$(MAKE) plan ENV=staging
	@$(MAKE) apply ENV=staging

prod: ## Quick deploy to production (with confirmation)
	@echo "$(RED)⚠️  Deploying to PRODUCTION environment$(RESET)"
	@read -p "Are you sure? Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ]
	@$(MAKE) init ENV=prod
	@$(MAKE) plan ENV=prod
	@$(MAKE) apply ENV=prod

# Dependency checks
init plan apply destroy: check-env