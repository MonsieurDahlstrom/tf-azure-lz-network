run "default_network" {
  command = apply
  module {
    source = "./examples"
  }

  assert {
    condition     = module.network.vnet_id != null
    error_message = "Virtual network should be created"
  }

  assert {
    condition     = length(module.network.subnets) == 5
    error_message = "${jsonencode(keys(module.network.subnets))} has ${length(module.network.subnets)} subnets, expected 5"
  }

  assert {
    condition     = length(module.network.subnet_ids) == 5
    error_message = "${jsonencode(keys(module.network.subnet_ids))} has ${length(module.network.subnet_ids)} subnets, expected 5"
  }

  assert {
    condition     = length(module.network.nsgs) == 5
    error_message = "${jsonencode(keys(module.network.nsgs))} has ${length(module.network.nsgs)} nsgs, expected 5"
  }

  assert {
    condition     = length(module.network.ingress_ip_map) == 2
    error_message = "${jsonencode(keys(module.network.ingress_ip_map))} has ${length(module.network.ingress_ip_map)} ips mapped, expected 5"
  }

  assert {
    condition     = length(module.network.subnets["aks_api"].delegation) == 1
    error_message = "aks_api subnet should have exactly one delegation"
  }

  assert {
    condition     = module.network.subnets["aks_api"].delegation[0].service_delegation[0].name == "Microsoft.ContainerService/managedClusters"
    error_message = "aks_api subnet should be delegated to Microsoft.ContainerService/managedClusters"
  }

  assert {
    condition     = contains(module.network.subnets["aks_api"].delegation[0].service_delegation[0].actions, "Microsoft.Network/virtualNetworks/subnets/join/action")
    error_message = "aks_api subnet delegation should include Microsoft.Network/virtualNetworks/subnets/join/action"
  }

  assert {
    condition     = length(module.network.subnets["aks_nodepool"].delegation) == 0
    error_message = "aks_nodepool subnet should not have any delegations"
  }

  assert {
    condition     = length(module.network.subnets["aks_ingress"].delegation) == 0
    error_message = "aks_ingress subnet should not have any delegations"
  }

  assert {
    condition     = length(module.network.subnets["private_endpoints"].delegation) == 0
    error_message = "private_endpoints subnet should not have any delegations"
  }
}

run "dns_resolver_network" {
  module {
    source = "./examples"
  }

  variables {
    enable_dns_resolver = true
  }

  assert {
    condition     = length(module.network.subnets) == 6
    error_message = "${jsonencode(keys(module.network.subnets))} has ${length(module.network.subnets)} subnets, expected 6"
  }

  assert {
    condition     = length(module.network.subnet_ids) == 6
    error_message = "${jsonencode(keys(module.network.subnet_ids))} has ${length(module.network.subnet_ids)} subnets, expected 6"
  }

  assert {
    condition     = length(module.network.nsgs) == 6
    error_message = "${jsonencode(keys(module.network.nsgs))} has ${length(module.network.nsgs)} nsgs, expected 6"
  }

  assert {
    condition     = can(cidrnetmask("${module.network.dns_resolver_ip_address}/32"))
    error_message = "DNS resolver should have valid ip, got ${module.network.dns_resolver_ip_address}"
  }

  assert {
    condition     = length(module.network.subnets["dns_resolver"].delegation) == 1
    error_message = "dns_resolver subnet should have exactly one delegation"
  }

  assert {
    condition     = module.network.subnets["dns_resolver"].delegation[0].service_delegation[0].name == "Microsoft.Network/dnsResolvers"
    error_message = "dns_resolver subnet should be delegated to Microsoft.Network/dnsResolvers"
  }

  assert {
    condition     = contains(module.network.subnets["dns_resolver"].delegation[0].service_delegation[0].actions, "Microsoft.Network/virtualNetworks/subnets/join/action")
    error_message = "dns_resolver subnet delegation should include Microsoft.Network/virtualNetworks/subnets/join/action"
  }
}

# Temporarily disabled until we can test with GitHub Enterprise accounts
# run "github_network_settings" {
#   module {
#     source = "./examples"
#   }
#
#   variables {
#     enable_github_network_settings = true
#     github_business_id = "test-business-id"
#   }
#
#   assert {
#     condition     = length(module.network.subnets) == 6
#     error_message = "${jsonencode(keys(module.network.subnets))} has ${length(module.network.subnets)} subnets, expected 6"
#   }
#
#   assert {
#     condition     = length(module.network.subnet_ids) == 6
#     error_message = "${jsonencode(keys(module.network.subnet_ids))} has ${length(module.network.subnet_ids)} subnets, expected 6"
#   }
#
#   assert {
#     condition     = length(module.network.nsgs) == 6
#     error_message = "${jsonencode(keys(module.network.nsgs))} has ${length(module.network.nsgs)} nsgs, expected 6"
#   }
#
#   assert {
#     condition     = module.network.github_network_id != null
#     error_message = "GitHub network ID should be created"
#   }
#
#   assert {
#     condition     = length(module.network.subnets["github_runners"].delegation) == 1
#     error_message = "github_runners subnet should have exactly one delegation"
#   }
#
#   assert {
#     condition     = module.network.subnets["github_runners"].delegation[0].service_delegation[0].name == "GitHub.Network/networkSettings"
#     error_message = "github_runners subnet should be delegated to GitHub.Network/networkSettings"
#   }
#
#   assert {
#     condition     = contains(module.network.subnets["github_runners"].delegation[0].service_delegation[0].actions, "Microsoft.Network/virtualNetworks/subnets/join/action")
#     error_message = "github_runners subnet delegation should include Microsoft.Network/virtualNetworks/subnets/join/action"
#   }
# }
