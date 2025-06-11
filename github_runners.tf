resource "azurerm_subnet" "github_runners" {
  count                = var.enable_github_network_settings ? 1 : 0
  name                 = "github-runners-subnet"
  resource_group_name  = data.azurerm_resource_group.parent.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.full_subnet_map["github_runners"]]

  delegation {
    name = "github-networksettings-delegation"
    service_delegation {
      name    = "GitHub.Network/networkSettings"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azapi_resource" "github_network_settings" {
  count     = var.enable_github_network_settings ? 1 : 0
  type      = "GitHub.Network/networkSettings@2024-04-02"
  name      = "github-network-settings"
  parent_id = data.azurerm_resource_group.parent.id
  body = {
    properties = {
      businessId = var.github_business_id
      subnetId   = azurerm_subnet.github_runners[0].id
    }
  }
  response_export_values = ["tags.GitHubId"]
} 