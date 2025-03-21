
output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  description = "Map of subnet names to their resource IDs"
  value       = { for k, subnet in azurerm_subnet.subnets : k => subnet.id }
}

output "dns_resolver_subnet_id" {
  description = "ID of the DNS resolver subnet (if created)"
  value       = try(azurerm_subnet.dns_resolver[0].id, null)
}

output "github_runners_subnet_id" {
  description = "ID of the GitHub runners subnet (if created)"
  value       = try(azurerm_subnet.github_runners[0].id, null)
}
