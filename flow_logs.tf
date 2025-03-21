resource "azurerm_network_watcher" "this" {
  name                = "NetworkWatcher_${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
}
