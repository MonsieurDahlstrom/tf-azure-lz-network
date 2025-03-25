terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.2"
    }
  }
}

variable "subscription_id" {
  type = string
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string
  default = null
}

variable "tenant_id" {
  type = string
}

variable "use_oidc" {
  type = bool
  default = false
}

variable "enable_dns_resolver" {
  type    = bool
  default = false
}

variable "enable_github_runner" {
  type    = bool
  default = false
}

variable "github_business_id" {
  type    = string
  default = "github-business-id"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.use_oidc ? null : var.client_secret
  tenant_id       = var.tenant_id
  use_oidc        = var.use_oidc
}

resource "random_pet" "bucket_prefix" {
  length = 4
}

resource "random_string" "storage_account_name" {
  length  = 20
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  name     = "rg-test-${random_pet.bucket_prefix.id}"
  location = "westeurope"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-test-${random_pet.bucket_prefix.id}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_storage_account" "this" {
  name                       = random_string.storage_account_name.result
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location
  account_tier               = "Standard"
  account_replication_type   = "LRS"
  https_traffic_only_enabled = true
}

module "network" {
  source                         = "../"
  resource_group_name            = azurerm_resource_group.this.name
  location                       = azurerm_resource_group.this.location
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.this.id
  flow_logs_storage_id           = azurerm_storage_account.this.id
  vnet_cidr                      = "10.0.0.0/22"
  enable_dns_resolver            = var.enable_dns_resolver
  enable_github_network_settings = var.enable_github_runner
  github_business_id             = var.github_business_id
}








