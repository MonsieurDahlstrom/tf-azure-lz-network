resource "azurerm_virtual_network" "this" {
  name                = "aks-landingzone-vnet"
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = data.azurerm_resource_group.parent.name
}


resource "azurerm_subnet" "subnets" {
  for_each = { for k, v in local.active_subnets : k => v if k != "dmz" }

  name                 = "${each.key}-subnet"
  resource_group_name  = data.azurerm_resource_group.parent.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value]

  # Add delegation for AKS API server subnet
  dynamic "delegation" {
    for_each = each.key == "aks_api" ? [1] : []
    content {
      name = "aks-api-delegation"
      service_delegation {
        name = "Microsoft.ContainerService/managedClusters"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/action"
        ]
      }
    }
  }
}


resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = { for k, v in local.active_subnets : k => v if k != "dmz" }

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsgs[each.key].id
}

resource "azurerm_subnet" "dmz" {
  name                 = "dmz-subnet"
  resource_group_name  = data.azurerm_resource_group.parent.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.full_subnet_map["dmz"]]
}

resource "azurerm_subnet_network_security_group_association" "dmz_nsg_assoc" {
  subnet_id                 = azurerm_subnet.dmz.id
  network_security_group_id = azurerm_network_security_group.nsg_dmz.id
}
