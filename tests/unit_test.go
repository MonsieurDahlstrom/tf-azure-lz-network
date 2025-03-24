//go:build unit
// +build unit

package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"tf-azure-lz-network/tests/testutil"
)

func TestNetworkModule(t *testing.T) {
	t.Run("Can be Planned with Default Values", func(t *testing.T) {
		terraformOptions := testutil.WithRetryableErrors(t)
		defer terraform.Destroy(t, terraformOptions)
		
		output := terraform.InitAndPlan(t, terraformOptions)
		assert.Contains(t, output, "Plan: 22 to add, 0 to change, 0 to destroy")
	})

	t.Run("Validates Required Variables", func(t *testing.T) {
		terraformOptions := testutil.DefaultTerraformOptions(t)
		delete(terraformOptions.Vars, "subscription_id")
		
		_, err := terraform.InitAndPlanE(t, terraformOptions)
		require.Error(t, err)
		assert.Contains(t, err.Error(), "subscription_id")
	})

	t.Run("Validates CIDR Format", func(t *testing.T) {
		terraformOptions := testutil.DefaultTerraformOptions(t)
		terraformOptions.Vars["vnet_cidr"] = "invalid-cidr"
		
		_, err := terraform.InitAndPlanE(t, terraformOptions)
		require.Error(t, err)
		assert.Contains(t, err.Error(), "vnet_cidr")
	})

	t.Run("Validates Feature Flags", func(t *testing.T) {
		terraformOptions := testutil.DefaultTerraformOptions(t)
		terraformOptions.Vars["enable_dns_resolver"] = true
		terraformOptions.Vars["enable_github_network_settings"] = true
		
		output := terraform.InitAndPlan(t, terraformOptions)
		assert.Contains(t, output, "Plan: 24 to add, 0 to change, 0 to destroy")
	})
}