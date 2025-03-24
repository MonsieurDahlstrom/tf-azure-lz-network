output "vnet_id" {
  description = "ID of the created Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "subnets" {
  description = "Map of subnet names to subnet objects"
  value = {
    for k, v in azurerm_subnet.subnets : k => v
  }
}

output "subnet_ids" {
  description = "Map of subnet names to subnet IDs"
  value = {
    for k, v in azurerm_subnet.subnets : k => v.id
  }
}

output "nsgs" {
  description = "Map of NSG names to NSG objects"
  value = {
    for k, v in azurerm_network_security_group.nsgs : k => v
  }
}
