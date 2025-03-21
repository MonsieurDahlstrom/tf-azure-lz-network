//go:build unit
// +build unit

package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestAKS(t *testing.T) {	
	t.Run("Can be Planned", func(t *testing.T) {
		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: "../example",
			Vars: map[string]interface{}{
				"vnet_cidr":                      "10.1.0.0/22",
				"enable_dns_resolver":            false,
				"enable_github_network_settings": false,
				"github_business_id":             "fake-business-id",
				"subscription_id":                "36d34e16-f9c7-4bbc-8d50-8a0cd588e058",
			},
			//VarFiles: []string{"varfile.tfvars"},
			NoColor: true,
		})
		defer terraform.Destroy(t, terraformOptions)
		output := terraform.InitAndPlan(t, terraformOptions)
		assert.Contains(t, output, "Plan: 22 to add, 0 to change, 0 to destroy")
	})
}