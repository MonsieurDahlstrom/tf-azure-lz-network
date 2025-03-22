terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.23.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.3.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {}
}

variable "vnet_cidr" {
  description = "CIDR range for the virtual network"
  type        = string
  default     = "10.1.0.0/22"
}

variable "enable_dns_resolver" {
  description = "Whether to enable DNS resolver for the network"
  type        = bool
  default     = true
}

variable "enable_github_network_settings" {
  description = "Whether to enable GitHub network settings"
  type        = bool
  default     = true
}

variable "github_business_id" {
  description = "GitHub business ID for network settings"
  type        = string
  default     = "fake-business-id"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

locals {
  solution      = "test"
  business_area = "da"
  location      = "norwayeast"
  common_tags = {
    created_by = "terratest"
    created_on = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
    solution   = local.solution
    env        = "test"
  }
}

resource "random_string" "name_suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.solution}-${random_string.name_suffix.result}"
  location = local.location
  tags     = local.common_tags
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${local.solution}-${random_string.name_suffix.result}"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_storage_account" "st" {
  name                       = "st${local.solution}${random_string.name_suffix.result}"
  location                   = local.location
  resource_group_name        = azurerm_resource_group.rg.name
  account_tier               = "Standard"
  account_kind               = "StorageV2"
  account_replication_type   = "LRS"
  https_traffic_only_enabled = true
  tags                       = local.common_tags
}

module "landingzone_network" {
  source                         = "../"
  resource_group_name            = azurerm_resource_group.rg.name
  location                       = local.location
  vnet_cidr                      = var.vnet_cidr
  enable_dns_resolver            = var.enable_dns_resolver
  enable_github_network_settings = var.enable_github_network_settings
  github_business_id             = var.github_business_id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law.id
  flow_logs_storage_id           = azurerm_storage_account.st.id
  subscription_id                = var.subscription_id
}

output "vnet_id" {
  description = "The ID of the created virtual network"
  value       = module.landingzone_network.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = module.landingzone_network.subnet_ids
}

output "dns_resolver_subnet_id" {
  description = "The ID of the DNS resolver subnet"
  value       = module.landingzone_network.dns_resolver_subnet_id
}

output "github_runners_subnet_id" {
  description = "The ID of the GitHub runners subnet"
  value       = module.landingzone_network.github_runners_subnet_id
}