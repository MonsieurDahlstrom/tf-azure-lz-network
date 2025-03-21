locals {
  # Azure standard resource group for Network Watchers - should never change
  network_watcher_rg_name = "NetworkWatcherRG"
  # Azure standard naming convention for Network Watchers
  network_watcher_name = "NetworkWatcher_${var.location}"
}

data "azurerm_log_analytics_workspace" "law" {
  name                = element(split("/", var.log_analytics_workspace_id), length(split("/", var.log_analytics_workspace_id)) - 1)
  resource_group_name = element(split("/", var.log_analytics_workspace_id), 4)
}

resource "azurerm_network_watcher_flow_log" "vnet_flow_logs" {
  name                = "flowlog-vnet"
  location            = var.location
  resource_group_name = local.network_watcher_rg_name
  network_watcher_name = local.network_watcher_name
  
  target_resource_id  = azurerm_virtual_network.this.id
  storage_account_id  = var.flow_logs_storage_id
  enabled             = true

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = data.azurerm_log_analytics_workspace.law.workspace_id
    workspace_region      = var.location
    workspace_resource_id = var.log_analytics_workspace_id
  }
}