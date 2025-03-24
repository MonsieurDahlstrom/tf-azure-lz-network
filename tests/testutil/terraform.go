package testutil

import (
	"github.com/gruntwork-io/terratest/modules/terraform"
)

// DefaultTerraformOptions returns common Terraform options used across tests
func DefaultTerraformOptions(t interface{}) *terraform.Options {
	return &terraform.Options{
		TerraformDir: "../example",
		Vars: map[string]interface{}{
			"vnet_cidr":                      "10.1.0.0/22",
			"enable_dns_resolver":            false,
			"enable_github_network_settings": false,
			"github_business_id":             "fake-business-id",
			"subscription_id":                "36d34e16-f9c7-4bbc-8d50-8a0cd588e058",
		},
		NoColor: true,
	}
}

// WithRetryableErrors returns Terraform options with retryable errors enabled
func WithRetryableErrors(t interface{}) *terraform.Options {
	return terraform.WithDefaultRetryableErrors(t, DefaultTerraformOptions(t))
} 