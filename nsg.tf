resource "azurerm_network_security_group" "nsgs" {
  for_each = { for k, v in local.active_subnets : k => v if k != "dmz" }

  name                = "nsg-${each.key}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.parent.name

  security_rule {
    name                       = "Allow-VNet-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}


resource "azurerm_network_security_group" "dns_resolver_nsg" {
  count               = var.enable_dns_resolver ? 1 : 0
  name                = "nsg-dns-resolver"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.parent.name

  dynamic "security_rule" {
    for_each = { for k, v in local.active_subnets : k => v if k != "dmz" }
    content {
      name                       = "Allow-DNS-from-${security_rule.key}"
      priority                   = 100 + index(keys(local.active_subnets), security_rule.key)
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Udp"
      source_port_range          = "*"
      source_address_prefix      = security_rule.value
      destination_port_range     = "53"
      destination_address_prefix = "*"
    }
  }
}


resource "azurerm_network_security_group" "nsg_dmz" {
  name                = "nsg-dmz"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.parent.name

  dynamic "security_rule" {
    for_each = local.dmz_http_source_prefixes
    content {
      name                       = "Allow-DMZ-To-Ingress-HTTP-${index(local.dmz_http_source_prefixes, security_rule.value)}"
      priority                   = 100 + index(local.dmz_http_source_prefixes, security_rule.value)
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = security_rule.value
      destination_address_prefix = local.full_subnet_map["aks_ingress"]
      destination_port_range     = "80"
    }
  }

  dynamic "security_rule" {
    for_each = local.dmz_https_source_prefixes
    content {
      name                       = "Allow-DMZ-To-Ingress-HTTPS-${index(local.dmz_https_source_prefixes, security_rule.value)}"
      priority                   = 200 + index(local.dmz_https_source_prefixes, security_rule.value)
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = security_rule.value
      destination_address_prefix = local.full_subnet_map["aks_ingress"]
      destination_port_range     = "443"
    }
  }

  dynamic "security_rule" {
    for_each = local.dmz_aks_api_source_prefixes
    content {
      name                       = "Allow-DMZ-To-AKSAPI-${index(local.dmz_aks_api_source_prefixes, security_rule.value)}"
      priority                   = 300 + index(local.dmz_aks_api_source_prefixes, security_rule.value)
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = security_rule.value
      destination_address_prefix = local.full_subnet_map["aks_api"]
      destination_port_range     = "443"
    }
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}
