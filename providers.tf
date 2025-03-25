terraform {
  required_version = ">= 1.0.0"
  required_providers {
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