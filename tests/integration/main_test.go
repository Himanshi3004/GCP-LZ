package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestLandingZoneIntegration(t *testing.T) {
	terraformOptions := &terraform.Options{
		TerraformDir: "../../",
		Vars: map[string]interface{}{
			"project_id":        "test-project-123",
			"organization_id":   "123456789012",
			"billing_account":   "ABCDEF-123456-GHIJKL",
			"environment":       "test",
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Test organization structure
	orgOutput := terraform.Output(t, terraformOptions, "organization_folders")
	assert.NotEmpty(t, orgOutput)

	// Test project creation
	projectOutput := terraform.Output(t, terraformOptions, "project_ids")
	assert.NotEmpty(t, projectOutput)

	// Test networking
	vpcOutput := terraform.Output(t, terraformOptions, "vpc_network")
	assert.NotEmpty(t, vpcOutput)
}

func TestModuleIntegration(t *testing.T) {
	t.Run("IAM-Networking", func(t *testing.T) {
		terraformOptions := &terraform.Options{
			TerraformDir: "../../",
		}
		
		// Test IAM and networking integration
		terraform.InitAndPlan(t, terraformOptions)
	})

	t.Run("Security-Compliance", func(t *testing.T) {
		terraformOptions := &terraform.Options{
			TerraformDir: "../../",
		}
		
		// Test security and compliance integration
		terraform.InitAndPlan(t, terraformOptions)
	})
}