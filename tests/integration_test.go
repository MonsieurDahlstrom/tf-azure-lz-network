//go:build integration
// +build integration

package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// An example of how to test the simple Terraform module in examples/terraform-basic-example using Terratest.
func TestTerraformBasicExample(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../example",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"vnet_cidr":                      "10.1.0.0/22",
			"enable_dns_resolver":            false,
			"enable_github_network_settings": false,
			"github_business_id":             "fake-business-id",
			"subscription_id":                "36d34e16-f9c7-4bbc-8d50-8a0cd588e058",
		},
		 // Variables to pass to our Terraform code using -var-file options
        //VarFiles: []string{"varfile.tfvars"},
		
		// Disable colors in Terraform commands so its easier to parse stdout/stderr
		NoColor: true,
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables
	vnetID := terraform.Output(t, terraformOptions, "vnet_id")
	subnetIDs := terraform.OutputMap(t, terraformOptions, "subnet_ids")
	//dnsSubnetID := terraform.Output(t, terraformOptions, "dns_resolver_subnet_id")
	//githubSubnetID := terraform.Output(t, terraformOptions, "github_runners_subnet_id")

	// Verify we're getting correct outputs
	assert.Contains(t, vnetID, "/virtualNetworks/")
	assert.NotEmpty(t, subnetIDs)
	
	// DNS resolver subnet should be empty since we disabled it
	//assert.Empty(t, dnsSubnetID)
	
	// GitHub runners subnet should be empty since we disabled it
	//assert.Empty(t, githubSubnetID)
}
