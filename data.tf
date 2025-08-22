data "azurerm_network_interface" "wan_primary" {
  name                = var.wan_nic_name_primary
  resource_group_name = var.resource_group_name
}

data "azurerm_network_interface" "lan_primary" {
  name                = var.lan_nic_name_primary
  resource_group_name = var.resource_group_name
}

data "azurerm_network_interface" "wan_secondary" {
  name                = var.wan_nic_name_secondary
  resource_group_name = var.resource_group_name
}

data "azurerm_network_interface" "lan_secondary" {
  name                = var.lan_nic_name_secondary
  resource_group_name = var.resource_group_name
}

data "azurerm_resource_group" "data-azure-rg" {
  name = var.resource_group_name
}

data "cato_accountSnapshotSite" "azure-site" {
  id = cato_socket_site.azure-site.id
}

data "cato_accountSnapshotSite" "azure-site-secondary" {
  depends_on = [time_sleep.sleep_30_seconds]
  id         = cato_socket_site.azure-site.id
}

data "azurerm_network_interface" "wannicmac" {
  name                = var.wan_nic_name_primary
  resource_group_name = var.resource_group_name
  depends_on          = [time_sleep.sleep_5_seconds]
}

data "azurerm_network_interface" "lannicmac" {
  name                = var.lan_nic_name_primary
  resource_group_name = var.resource_group_name
  depends_on          = [time_sleep.sleep_5_seconds]
}

data "azurerm_network_interface" "wannicmac-2" {
  name                = var.wan_nic_name_secondary
  resource_group_name = var.resource_group_name
  depends_on          = [time_sleep.sleep_5_seconds-2]
}

data "azurerm_network_interface" "lannicmac-2" {
  name                = var.lan_nic_name_secondary
  resource_group_name = var.resource_group_name
  depends_on          = [time_sleep.sleep_5_seconds-2]
}

data "cato_accountSnapshotSite" "azure-site-2" {
  id         = cato_socket_site.azure-site.id
  depends_on = [time_sleep.sleep_before_delete]
}
