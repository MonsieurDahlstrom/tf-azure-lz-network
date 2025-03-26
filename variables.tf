data "azurerm_resource_group" "parent" {
  name = var.resource_group_name
}

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

  validation {
    condition     = can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}/22$", var.vnet_cidr))
    error_message = "The vnet_cidr value must be a valid IPv4 CIDR block with a /22 prefix length."
  }
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
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
  description = "GitHub business ID for runner scale set integration. Required when enable_github_network_settings is true."
  type        = string
  default     = null
}

variable "cloudflare_ip_ranges" {
  description = "Cloudflare's public IP ranges"
  type        = list(string)
  default = [
    # 104.x.x.x ranges (consolidated)
    "104.16.0.0/13", # Covers 104.16.0.0 - 104.23.255.255
    "104.24.0.0/14", # Covers 104.24.0.0 - 104.27.255.255
    "104.28.0.0/15", # Covers 104.28.0.0 - 104.29.255.255
    "104.30.0.0/15", # Covers 104.30.0.0 - 104.31.255.255

    # 103.x.x.x ranges (cannot be consolidated)
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",

    # Other ranges (each in different network spaces)
    "108.162.192.0/18",
    "141.101.64.0/18",
    "162.158.0.0/15",
    "173.245.48.0/20",
    "188.114.96.0/20",
    "190.93.240.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17"
  ]
}

variable "cgnat_ip_ranges" {
  description = "CGNAT IP ranges"
  type        = list(string)
  default     = ["100.64.0.0/10"]
}

variable "dmz_http_source_prefixes" {
  description = "Source address prefixes for HTTP traffic to DMZ (default: CGNAT and Cloudflare IP ranges)"
  type        = list(string)
  default     = null
}

variable "dmz_https_source_prefixes" {
  description = "Source address prefixes for HTTPS traffic to DMZ (default: CGNAT and Cloudflare IP ranges)"
  type        = list(string)
  default     = null
}

variable "dmz_aks_api_source_prefixes" {
  description = "Source address prefixes for AKS API traffic to DMZ (default: CGNAT IP ranges)"
  type        = list(string)
  default     = null
}

variable "ingress_ip_names" {
  description = "List of names that will be converted to a map with IP addresses from the AKS ingress subnet"
  type        = list(string)
  default     = ["internal", "external"]

  validation {
    condition     = length(var.ingress_ip_names) <= 60
    error_message = "The ingress_ip_names list cannot contain more than 60 names as the subnet only has 60 available IP addresses (64 total - 4 reserved)."
  }
}

locals {
  # Default source prefixes
  default_dmz_http_source_prefixes    = concat(var.cgnat_ip_ranges, var.cloudflare_ip_ranges)
  default_dmz_https_source_prefixes   = concat(var.cgnat_ip_ranges, var.cloudflare_ip_ranges)
  default_dmz_aks_api_source_prefixes = var.cgnat_ip_ranges

  # Use provided values or defaults
  dmz_http_source_prefixes    = coalesce(var.dmz_http_source_prefixes, local.default_dmz_http_source_prefixes)
  dmz_https_source_prefixes   = coalesce(var.dmz_https_source_prefixes, local.default_dmz_https_source_prefixes)
  dmz_aks_api_source_prefixes = coalesce(var.dmz_aks_api_source_prefixes, local.default_dmz_aks_api_source_prefixes)

  full_subnet_map = {
    # Primary subnets - occupy larger parts of the address space
    aks_nodepool   = cidrsubnet(var.vnet_cidr, 2, 0) # /24 - first quarter
    github_runners = cidrsubnet(var.vnet_cidr, 2, 1) # /24 - second quarter

    # Medium subnets - occupy portions of the third quarter
    aks_ingress       = cidrsubnet(var.vnet_cidr, 4, 8) # /26 - first half of 3rd quarter
    private_endpoints = cidrsubnet(var.vnet_cidr, 4, 9) # /26 - second half of 3rd quarter

    # Small subnets - occupy portions of the fourth quarter
    aks_api      = cidrsubnet(var.vnet_cidr, 6, 48) # /28 - 1/16 of 4th quarter
    dmz          = cidrsubnet(var.vnet_cidr, 6, 49) # /28 - 1/16 of 4th quarter
    jumpbox      = cidrsubnet(var.vnet_cidr, 6, 50) # /28 - 1/16 of 4th quarter
    management   = cidrsubnet(var.vnet_cidr, 6, 51) # /28 - 1/16 of 4th quarter
    dns_resolver = cidrsubnet(var.vnet_cidr, 6, 52) # /28 - 1/16 of 4th quarter

    # Medium reserved subnets - occupy portions of the fourth quarter
    firewall    = cidrsubnet(var.vnet_cidr, 5, 28) # /27 - 1/8 of 4th quarter
    bastion     = cidrsubnet(var.vnet_cidr, 5, 29) # /27 - 1/8 of 4th quarter
    integration = cidrsubnet(var.vnet_cidr, 5, 30) # /27 - 1/8 of 4th quarter
  }

  active_subnet_keys = [
    "aks_nodepool", "aks_ingress", "private_endpoints", "aks_api", "dmz"
  ]

  active_subnets = { for k, v in local.full_subnet_map : k => v if contains(local.active_subnet_keys, k) }

  # Create a map of ingress IP names to their IP addresses
  ingress_ip_map = {
    for name in var.ingress_ip_names : name => cidrhost(local.full_subnet_map["aks_ingress"], index(var.ingress_ip_names, name) + 4)
  }
}
