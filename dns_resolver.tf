resource "azurerm_subnet" "dns_resolver" {
  count                = var.enable_dns_resolver ? 1 : 0
  name                 = "dns-resolver-subnet"
  resource_group_name  = data.azurerm_resource_group.parent.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.full_subnet_map["dns_resolver"]]

  delegation {
    name = "dns-resolver-delegation"
    service_delegation {
      name = "Microsoft.Network/dnsResolvers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "dns_resolver_assoc" {
  count                     = var.enable_dns_resolver ? 1 : 0
  subnet_id                 = azurerm_subnet.dns_resolver[0].id
  network_security_group_id = azurerm_network_security_group.dns_resolver_nsg[0].id
}

resource "azurerm_private_dns_resolver" "dns_resolver" {
  count               = var.enable_dns_resolver ? 1 : 0
  name                = "dns-resolver"
  resource_group_name = data.azurerm_resource_group.parent.name
  location            = var.location
  virtual_network_id  = azurerm_virtual_network.this.id
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "dns_resolver_inbound" {
  count                   = var.enable_dns_resolver ? 1 : 0
  name                    = "dns-resolver-inbound"
  private_dns_resolver_id = azurerm_private_dns_resolver.dns_resolver[0].id
  location                = var.location

  ip_configurations {
    subnet_id = azurerm_subnet.dns_resolver[0].id
  }
} 