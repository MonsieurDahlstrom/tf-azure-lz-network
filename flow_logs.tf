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

  # This lifecycle block helps ensure proper cleanup of associated Data Collection Rules
  lifecycle {
    # Force replacement of any Data Collection Rule associations when this resource changes
    create_before_destroy = true
  }
}

# This null_resource manages cleanup of orphaned Data Collection resources created by Network Watcher Flow Logs
resource "null_resource" "dcr_cleanup" {
  # Trigger recreation whenever the flow log resource changes
  triggers = {
    flow_log_id = azurerm_network_watcher_flow_log.vnet_flow_logs.id
    # Store information needed for destroy-time provisioner
    network_watcher_rg = local.network_watcher_rg_name
    module_rg = var.resource_group_name  # Module's resource group where data collection resources are created
    subscription_id = data.azurerm_client_config.current.subscription_id
    # Include script paths in triggers to recreate if scripts change
    bash_script_path = "${path.module}/dcr_cleanup.sh"
    ps_script_path = "${path.module}/dcr_cleanup.ps1"
    # Store OS information for cross-platform support
    is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true
  }

  # Make sure the bash script is executable on Unix/Linux systems
  provisioner "local-exec" {
    command = self.triggers.is_windows ? "echo 'Windows detected, skipping chmod'" : "chmod +x ${path.module}/dcr_cleanup.sh"
    interpreter = self.triggers.is_windows ? ["PowerShell", "-Command"] : ["bash", "-c"]
  }

  # Only run during destroy operations
  provisioner "local-exec" {
    when    = destroy
    # Choose appropriate script and interpreter based on OS
    # For Windows systems, use PowerShell
    # For Linux/Unix systems, use Bash
    command = self.triggers.is_windows ? (
      "PowerShell -ExecutionPolicy Bypass -File ${path.module}/dcr_cleanup.ps1 -ResourceGroup ${self.triggers.module_rg} -SubscriptionId ${self.triggers.subscription_id} -NamePattern NWTA"
    ) : (
      "${path.module}/dcr_cleanup.sh ${self.triggers.module_rg} ${self.triggers.subscription_id} NWTA"
    )
    # The interpreter has no effect on Windows when using PowerShell
    interpreter = self.triggers.is_windows ? ["PowerShell", "-Command"] : ["bash", "-c"]
  }

  depends_on = [azurerm_network_watcher_flow_log.vnet_flow_logs]
}

# Data source to get current subscription info
data "azurerm_client_config" "current" {}