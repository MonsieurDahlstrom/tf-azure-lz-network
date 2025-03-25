run "default_network" {
  command = apply
  module {
    source = "./example"
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
}

run "dns_resolver_network" {
  module {
    source = "./example"
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
}

# Temporarily disabled until we can test with GitHub Enterprise accounts
# run "github_network_settings" {
#   module {
#     source = "./example"
#   }
#
#   variables {
#     enable_github_runner = true
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
# }
