output "vnet_id" {
  description = "ID of the created Virtual Network"
  value       = azurerm_virtual_network.this.id
}

output "subnets" {
  description = "Map of subnet names to subnet objects"
  value = merge(
    {
      for k, v in azurerm_subnet.subnets : k => v
    },
    {
      dmz = azurerm_subnet.dmz
    },
    var.enable_dns_resolver ? {
      dns_resolver = azurerm_subnet.dns_resolver[0]
    } : {},
    var.enable_github_network_settings ? {
      github_runners = azurerm_subnet.github_runners[0]
    } : {}
  )
}

output "subnet_ids" {
  description = "Map of subnet names to subnet IDs"
  value = merge(
    {
      for k, v in azurerm_subnet.subnets : k => v.id
    },
    {
      dmz = azurerm_subnet.dmz.id
    },
    var.enable_dns_resolver ? {
      dns_resolver = azurerm_subnet.dns_resolver[0].id
    } : {},
    var.enable_github_network_settings ? {
      github_runners = azurerm_subnet.github_runners[0].id
    } : {}
  )
}

output "nsgs" {
  description = "Map of NSG names to NSG objects"
  value = merge(
    {
      for k, v in azurerm_network_security_group.nsgs : k => v
    },
    {
      dmz = azurerm_network_security_group.nsg_dmz
    },
    var.enable_dns_resolver ? {
      dns_resolver = azurerm_network_security_group.dns_resolver_nsg[0]
    } : {}
  )
}

output "github_network_id" {
  value       = try(azapi_resource.github_network_settings[0].output["tags"]["GitHubId"], null)
  description = "GitHub ID returned from the GitHub network settings resource"
}

output "dns_resolver_ip_address" {
  description = "IP address of the DNS resolver inbound endpoint"
  value       = try(azurerm_private_dns_resolver_inbound_endpoint.dns_resolver_inbound[0].ip_configurations[0].private_ip_address, null)
}

output "ingress_ip_map" {
  description = "Map of ingress names to their IP addresses from the AKS ingress subnet"
  value       = local.ingress_ip_map
}
