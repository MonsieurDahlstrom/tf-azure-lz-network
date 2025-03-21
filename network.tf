resource "azurerm_virtual_network" "this" {
  name                = "aks-landingzone-vnet"
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
}


resource "azurerm_subnet" "subnets" {
  for_each = { for k, v in local.active_subnets : k => v if k != "dmz" }

  name                 = "${each.key}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value]
}


resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = { for k, v in local.active_subnets : k => v if k != "dmz" }

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsgs[each.key].id
}


resource "azurerm_subnet" "dns_resolver" {
  count                = var.enable_dns_resolver ? 1 : 0
  name                 = "dns-resolver-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.full_subnet_map["dns_resolver"]]
}


resource "azurerm_subnet_network_security_group_association" "dns_resolver_assoc" {
  count                     = var.enable_dns_resolver ? 1 : 0
  subnet_id                 = azurerm_subnet.dns_resolver[0].id
  network_security_group_id = azurerm_network_security_group.dns_resolver_nsg[0].id
}


resource "azurerm_subnet" "github_runners" {
  count                = var.enable_github_network_settings ? 1 : 0
  name                 = "github-runners-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.full_subnet_map["github_runners"]]

  delegation {
    name = "github-networksettings-delegation"
    service_delegation {
      name = "Microsoft.GitHub/networkSettings"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}


resource "azapi_resource" "github_network_settings" {
  count     = var.enable_github_network_settings ? 1 : 0
  type      = "Microsoft.GitHub/networkSettings@2024-04-02"
  name      = "github-network-settings"
  location  = var.location
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"

  schema_validation_enabled = false

  body = jsonencode({
    properties = {
      businessId = var.github_business_id
      subnetId   = azurerm_subnet.github_runners[0].id
    }
  })

  response_export_values = ["tags.GitHubId"]
}

output "github_network_id" {
  value       = try(azapi_resource.github_network_settings[0].output["tags"]["GitHubId"], null)
  description = "GitHub ID returned from the GitHub network settings resource"
}


resource "azurerm_subnet_network_security_group_association" "dmz_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnets["dmz"].id
  network_security_group_id = azurerm_network_security_group.nsg_dmz.id
}
