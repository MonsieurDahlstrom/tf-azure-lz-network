package test

import (
    "context"
    "os"
    "testing"
    "strings"

    armnetwork "github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/network/armnetwork/v2"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
    "github.com/Azure/azure-sdk-for-go/sdk/azidentity"
)

func TestTerraformModule(t *testing.T) {
    t.Parallel()

    terraformOptions := &terraform.Options{
        TerraformDir: "..",
        Vars: map[string]interface{}{
            "vnet_cidr":                        "10.1.0.0/22",
            "location":                         "eastus",
            "resource_group_name":              "terratest-rg",
            "subscription_id":                  os.Getenv("ARM_SUBSCRIPTION_ID"),
            "enable_dns_resolver":              true,
            "enable_github_network_settings":   true,
            "github_business_id":               "fake-business-id",
            "log_analytics_workspace_id":       "/subscriptions/dummy/resourceGroups/logs/providers/Microsoft.OperationalInsights/workspaces/example",
            "nsg_flow_logs_storage_id":         "/subscriptions/dummy/resourceGroups/logs/providers/Microsoft.Storage/storageAccounts/example",
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    vnetID := terraform.Output(t, terraformOptions, "vnet_id")
    assert.True(t, strings.Contains(vnetID, "/virtualNetworks/"), "VNet ID should be valid")

    subnetIDs := terraform.OutputMap(t, terraformOptions, "subnet_ids")
    assert.GreaterOrEqual(t, len(subnetIDs), 5, "Should create at least 5 active subnets")

    dnsSubnetID := terraform.Output(t, terraformOptions, "dns_resolver_subnet_id")
    githubSubnetID := terraform.Output(t, terraformOptions, "github_runners_subnet_id")
    assert.NotEmpty(t, dnsSubnetID, "DNS resolver subnet should be created")
    assert.NotEmpty(t, githubSubnetID, "GitHub runners subnet should be created")

    cred, err := azidentity.NewDefaultAzureCredential(nil)
    assert.NoError(t, err)

    nsgClient, err := armnetwork.NewSecurityGroupsClient(os.Getenv("ARM_SUBSCRIPTION_ID"), cred, nil)
    assert.NoError(t, err)

    ctx := context.Background()

    // Validate DMZ NSG has 443
    dmzNSG, err := nsgClient.Get(ctx, "terratest-rg", "nsg-dmz", nil)
    assert.NoError(t, err)

    found443 := false
    for _, rule := range dmzNSG.Properties.SecurityRules {
        if rule.Properties != nil && rule.Properties.DestinationPortRange != nil {
            if *rule.Properties.DestinationPortRange == "443" {
                found443 = true
                break
            }
        }
    }
    assert.True(t, found443, "DMZ NSG should contain a rule allowing port 443")

    // Validate DNS resolver NSG has UDP 53
    dnsNSG, err := nsgClient.Get(ctx, "terratest-rg", "nsg-dns-resolver", nil)
    assert.NoError(t, err)

    foundDNS := false
    for _, rule := range dnsNSG.Properties.SecurityRules {
        if rule.Properties != nil &&
            rule.Properties.DestinationPortRange != nil &&
            *rule.Properties.DestinationPortRange == "53" &&
            strings.ToLower(*rule.Properties.Protocol) == "udp" {
            foundDNS = true
            break
        }
    }
    assert.True(t, foundDNS, "DNS Resolver NSG should contain a UDP rule for port 53")

    // Validate GitHub runners NSG has Deny-All-Inbound and Allow-All-Outbound
    runnersNSG, err := nsgClient.Get(ctx, "terratest-rg", "nsg-github-runners", nil)
    assert.NoError(t, err)

    foundDenyInbound := false
    foundAllowOutbound := false

    for _, rule := range runnersNSG.Properties.SecurityRules {
        if rule.Properties != nil && rule.Properties.Direction != nil {
            dir := strings.ToLower(*rule.Properties.Direction)
            if dir == "inbound" && strings.ToLower(*rule.Properties.Access) == "deny" {
                foundDenyInbound = true
            } else if dir == "outbound" && strings.ToLower(*rule.Properties.Access) == "allow" {
                foundAllowOutbound = true
            }
        }
    }

    assert.True(t, foundDenyInbound, "GitHub runners NSG should deny all inbound traffic")
    assert.True(t, foundAllowOutbound, "GitHub runners NSG should allow all outbound traffic")
}


    // Validate DNS Resolver Subnet Delegation
    subnetClient, err := armnetwork.NewSubnetsClient(os.Getenv("ARM_SUBSCRIPTION_ID"), cred, nil)
    assert.NoError(t, err)

    dnsSubnet, err := subnetClient.Get(ctx, "terratest-rg", "aks-landingzone-vnet", "dns-resolver-subnet", nil)
    assert.NoError(t, err)

    foundDNSDelegation := false
    if dnsSubnet.Properties != nil && dnsSubnet.Properties.Delegations != nil {
        for _, del := range dnsSubnet.Properties.Delegations {
            if del.Properties != nil && strings.EqualFold(*del.Properties.ServiceName, "Microsoft.Network/dnsResolvers") {
                foundDNSDelegation = true
                break
            }
        }
    }
    assert.True(t, foundDNSDelegation, "DNS Resolver subnet must be delegated to Microsoft.Network/dnsResolvers")

    // Validate GitHub Runners Subnet Delegation
    githubSubnet, err := subnetClient.Get(ctx, "terratest-rg", "aks-landingzone-vnet", "github-runners-subnet", nil)
    assert.NoError(t, err)

    foundGitHubDelegation := false
    if githubSubnet.Properties != nil && githubSubnet.Properties.Delegations != nil {
        for _, del := range githubSubnet.Properties.Delegations {
            if del.Properties != nil && strings.EqualFold(*del.Properties.ServiceName, "Microsoft.GitHub/networkSettings") {
                foundGitHubDelegation = true
                break
            }
        }
    }
    assert.True(t, foundGitHubDelegation, "GitHub Runners subnet must be delegated to Microsoft.GitHub/networkSettings")
