variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace ID"
}

variable "flow_logs_storage_id" {
  type        = string
  description = "Storage Account ID for Virtual Network Flow Logs"
}


variable "vnet_cidr" {
  description = "CIDR block for the VNet (must be /22)"
  type        = string
}

variable "location" {
  type        = string
}

variable "resource_group_name" {
  type        = string
}

variable "subscription_id" {
  type        = string
}

variable "enable_dns_resolver" {
  description = "Enable subnet and NSG for private DNS resolver"
  type        = bool
  default     = false
}

variable "enable_github_network_settings" {
  description = "Enable GitHub runner subnet and network settings"
  type        = bool
  default     = false
}

variable "github_business_id" {
  description = "GitHub business ID for runner scale set integration"
  type        = string
}

locals {
  full_subnet_map = {
    aks_nodepool         = cidrsubnet(var.vnet_cidr, 0, 0)  # /24
    aks_ingress          = cidrsubnet(var.vnet_cidr, 2, 0)  # /26
    private_endpoints    = cidrsubnet(var.vnet_cidr, 2, 1)  # /26
    aks_api              = cidrsubnet(var.vnet_cidr, 4, 4)  # /28
    dmz                  = cidrsubnet(var.vnet_cidr, 4, 5)  # /28
    firewall             = cidrsubnet(var.vnet_cidr, 2, 2)  # /26 (reserved)
    bastion              = cidrsubnet(var.vnet_cidr, 3, 6)  # /27 (reserved)
    jumpbox              = cidrsubnet(var.vnet_cidr, 4, 6)  # /28 (reserved)
    management           = cidrsubnet(var.vnet_cidr, 4, 7)  # /28 (reserved)
    integration          = cidrsubnet(var.vnet_cidr, 2, 3)  # /26 (reserved)
    dns_resolver         = cidrsubnet(var.vnet_cidr, 4, 8)  # /28 (conditional)
    github_runners       = cidrsubnet(var.vnet_cidr, 1, 1)  # /25 (conditional)
  }

  active_subnet_keys = [
    "aks_nodepool", "aks_ingress", "private_endpoints", "aks_api", "dmz"
  ]

  active_subnets = { for k, v in local.full_subnet_map : k => v if contains(local.active_subnet_keys, k) }
}
