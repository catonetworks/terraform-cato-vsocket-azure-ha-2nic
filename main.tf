resource "random_string" "vsocket-random-username" {
  length  = 16
  special = false
}

resource "random_string" "vsocket-random-password" {
  length  = 16
  special = false
  upper   = true
  lower   = true
  numeric = true
}
## VNET Module Resources
resource "cato_socket_site" "azure-site" {
  connection_type = "SOCKET_AZ1500"
  description     = var.site_description
  name            = var.site_name
  native_range = {
    native_network_range = var.subnet_range_lan
    local_ip             = data.azurerm_network_interface.lan_primary.private_ip_address
  }
  site_location = local.cur_site_location
  site_type     = var.site_type
}

# Create HA user Assigned Identity
resource "azurerm_user_assigned_identity" "CatoHaIdentity" {
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = local.ha_identity_name_local
  tags                = var.tags
}

# Create Primary Vsocket Virtual Machine
resource "azurerm_linux_virtual_machine" "vsocket_primary" {
  location      = var.location
  name          = local.vsocket_primary_name_local
  computer_name = local.vsocket_primary_name_local
  size          = var.vm_size
  network_interface_ids = [
    data.azurerm_network_interface.wan_primary.id,
    data.azurerm_network_interface.lan_primary.id
  ]
  resource_group_name = var.resource_group_name

  availability_set_id = var.availability_set_id
  zone                = var.vsocket_primary_zone

  disable_password_authentication = false
  provision_vm_agent              = true
  allow_extension_operations      = true

  admin_username = random_string.vsocket-random-username.result
  admin_password = "${random_string.vsocket-random-password.result}@"

  # Assign CatoHaIdentity to the Vsocket
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.CatoHaIdentity.id]
  }

  # OS disk configuration from variables
  os_disk {
    name                 = local.vsocket_primary_disk_name_local
    caching              = var.vm_os_disk_config.caching
    storage_account_type = var.vm_os_disk_config.storage_account_type
    disk_size_gb         = var.vm_os_disk_config.disk_size_gb
  }

  # Boot diagnostics controlled by a boolean variable
  boot_diagnostics {
    # An empty string enables managed boot diagnostics. `null` disables the block.
    storage_account_uri = var.enable_boot_diagnostics ? "" : null
  }

  # Plan information from the image configuration variable
  plan {
    name      = var.vm_image_config.sku
    publisher = var.vm_image_config.publisher
    product   = var.vm_image_config.product
  }

  # Source image reference from the image configuration variable
  source_image_reference {
    publisher = var.vm_image_config.publisher
    offer     = var.vm_image_config.offer
    sku       = var.vm_image_config.sku
    version   = var.vm_image_config.version
  }


  depends_on = [
    cato_socket_site.azure-site,
    data.cato_accountSnapshotSite.azure-site,
    data.cato_accountSnapshotSite.azure-site-2
  ]
  tags = var.tags
}


# To allow mac address to be retrieved for Primary nics
resource "time_sleep" "sleep_5_seconds" {
  create_duration = "5s"
  depends_on      = [azurerm_linux_virtual_machine.vsocket_primary]
}

variable "commands" {
  type = list(string)
  default = [
    "rm /cato/deviceid.txt",
    "rm /cato/socket/configuration/socket_registration.json",
    "nohup /cato/socket/run_socket_daemon.sh &"
  ]
}

resource "azurerm_virtual_machine_extension" "vsocket-custom-script-primary" {
  auto_upgrade_minor_version = true
  name                       = "vsocket-custom-script-primary"
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  virtual_machine_id         = azurerm_linux_virtual_machine.vsocket_primary.id
  lifecycle {
    ignore_changes = all
  }
  settings = <<SETTINGS
{
  "commandToExecute": "echo '${local.primary_serial[0]}' > /cato/serial.txt; echo '{\"wan_nic\":\"${data.azurerm_network_interface.wan_primary.name}\",\"wan_nic_mac\":\"${lower(replace(data.azurerm_network_interface.wannicmac.mac_address, "-", ":"))}\",\"wan_nic_ip\":\"${data.azurerm_network_interface.wan_primary.private_ip_address}\",\"lan_nic\":\"${data.azurerm_network_interface.lan_primary.name}\",\"lan_nic_mac\":\"${lower(replace(data.azurerm_network_interface.lannicmac.mac_address, "-", ":"))}\",\"lan_nic_ip\":\"${data.azurerm_network_interface.lan_primary.private_ip_address}\"}' > /cato/nics_config.json; ${join(";", var.commands)}"
}
SETTINGS

  depends_on = [
    azurerm_linux_virtual_machine.vsocket_primary,
    data.azurerm_network_interface.lannicmac,
    data.azurerm_network_interface.wannicmac
  ]
  tags = var.tags
}

# To allow socket to upgrade, so secondary socket can be added
resource "time_sleep" "sleep_300_seconds" {
  create_duration = "300s"
  depends_on      = [azurerm_virtual_machine_extension.vsocket-custom-script-primary]
}

#################################################################################
# Add secondary socket to site via API until socket_site resource is updated to natively support


# Sleep to allow Secondary vSocket serial retrieval
resource "time_sleep" "sleep_30_seconds" {
  create_duration = "30s"
  depends_on      = [terraform_data.configure_secondary_azure_vsocket]
}

# Create Primary Vsocket Virtual Machine
resource "azurerm_linux_virtual_machine" "vsocket_secondary" {
  location      = var.location
  name          = local.vsocket_secondary_name_local
  computer_name = local.vsocket_secondary_name_local
  size          = var.vm_size
  network_interface_ids = [
    data.azurerm_network_interface.wan_secondary.id,
    data.azurerm_network_interface.lan_secondary.id
  ]
  resource_group_name = var.resource_group_name

  availability_set_id = var.availability_set_id
  zone                = var.vsocket_secondary_zone

  disable_password_authentication = false
  provision_vm_agent              = true
  allow_extension_operations      = true

  admin_username = random_string.vsocket-random-username.result
  admin_password = "${random_string.vsocket-random-password.result}@"

  # Assign CatoHaIdentity to the Vsocket
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.CatoHaIdentity.id]
  }

  # OS disk configuration from image
  os_disk {
    name                 = local.vsocket_secondary_disk_name_local
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 8
  }

  # Boot diagnostics
  boot_diagnostics {
    storage_account_uri = "" # Empty string enables boot diagnostics
  }

  plan {
    name      = "public-cato-socket"
    publisher = "catonetworks"
    product   = "cato_socket"
  }

  source_image_reference {
    publisher = "catonetworks"
    offer     = "cato_socket"
    sku       = "public-cato-socket"
    version   = "latest"
  }


  depends_on = [
    data.cato_accountSnapshotSite.azure-site-secondary,
    terraform_data.configure_secondary_azure_vsocket,
    data.cato_accountSnapshotSite.azure-site-2
  ]
  tags = var.tags
}


#Sleep to allow Secondary vSocket interface mac address retrieval
resource "time_sleep" "sleep_5_seconds-2" {
  create_duration = "5s"
  depends_on      = [azurerm_linux_virtual_machine.vsocket_secondary]
}

resource "azurerm_virtual_machine_extension" "vsocket-custom-script-secondary" {
  auto_upgrade_minor_version = true
  name                       = "vsocket-custom-script-secondary"
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  virtual_machine_id         = azurerm_linux_virtual_machine.vsocket_secondary.id
  lifecycle {
    ignore_changes = all
  }
  settings = <<SETTINGS
 {
  "commandToExecute": "echo '${local.secondary_serial[0]}' > /cato/serial.txt; echo '{\"wan_nic\":\"${data.azurerm_network_interface.wan_secondary.name}\",\"wan_nic_mac\":\"${lower(replace(data.azurerm_network_interface.wannicmac-2.mac_address, "-", ":"))}\",\"wan_nic_ip\":\"${data.azurerm_network_interface.wan_secondary.private_ip_address}\",\"lan_nic\":\"${data.azurerm_network_interface.lan_secondary.name}\",\"lan_nic_mac\":\"${lower(replace(data.azurerm_network_interface.lannicmac-2.mac_address, "-", ":"))}\",\"lan_nic_ip\":\"${data.azurerm_network_interface.lan_secondary.private_ip_address}\"}' > /cato/nics_config.json; ${join(";", var.commands)}"
 }
SETTINGS
  depends_on = [
    azurerm_linux_virtual_machine.vsocket_secondary
  ]
  tags = var.tags
}

# Configure Secondary Azure vSocket via API
resource "terraform_data" "configure_secondary_azure_vsocket" {
  depends_on = [time_sleep.sleep_300_seconds]

  provisioner "local-exec" {
    # This command is generated from a template to keep the main file clean.
    # It sends a GraphQL mutation to an API endpoint.
    command = templatefile("${path.module}/templates/configure_secondary_azure_vsocket.tftpl", {
      api_token    = var.token
      base_url     = var.baseurl
      account_id   = var.account_id
      floating_ip  = var.floating_ip
      interface_ip = data.azurerm_network_interface.lan_secondary.private_ip_address
      site_id      = cato_socket_site.azure-site.id
    })
  }

  triggers_replace = {
    account_id = var.account_id
    site_id    = cato_socket_site.azure-site.id
  }
}


# Create HA Settings Secondary
resource "terraform_data" "run_command_ha_primary" {
  provisioner "local-exec" {
    # This command is now generated from a template file.
    # The templatefile() function reads the template and injects the variables.
    command = templatefile("${path.module}/templates/run_command_ha_primary.tftpl", {
      resource_group_name  = var.resource_group_name
      vsocket_primary_name = local.vsocket_primary_name_local
      location             = var.location
      subscription_id      = var.azure_subscription_id
      vnet_name            = var.vnet_name
      subnet_name          = var.lan_subnet_name
      primary_nic_name     = data.azurerm_network_interface.lan_primary.name
      secondary_nic_name   = data.azurerm_network_interface.lan_secondary.name
      primary_nic_ip       = data.azurerm_network_interface.lan_primary.private_ip_address
      primary_nic_mac      = data.azurerm_network_interface.lannicmac.mac_address
      subnet_range_lan     = var.subnet_range_lan
    })
  }

  depends_on = [
    azurerm_virtual_machine_extension.vsocket-custom-script-secondary
  ]
}

resource "terraform_data" "run_command_ha_secondary" {
  provisioner "local-exec" {
    # This command is also generated from its own template file.
    command = templatefile("${path.module}/templates/run_command_ha_secondary.tftpl", {
      resource_group_name    = var.resource_group_name
      vsocket_secondary_name = local.vsocket_secondary_name_local
      location               = var.location
      subscription_id        = var.azure_subscription_id
      vnet_name              = var.vnet_name
      subnet_name            = var.lan_subnet_name
      primary_nic_name       = data.azurerm_network_interface.lan_primary.name
      secondary_nic_name     = data.azurerm_network_interface.lan_secondary.name
      secondary_nic_ip       = data.azurerm_network_interface.lan_secondary.private_ip_address
      secondary_nic_mac      = data.azurerm_network_interface.lannicmac-2.mac_address
      subnet_range_lan       = var.subnet_range_lan
    })
  }

  depends_on = [
    azurerm_virtual_machine_extension.vsocket-custom-script-secondary,
    terraform_data.run_command_ha_primary
  ]
}

# Reboot Primary vSocket
resource "terraform_data" "reboot_vsocket_primary" {
  provisioner "local-exec" {
    # The simple restart command is also templated for consistency.
    command = templatefile("${path.module}/templates/reboot_vsocket_primary.tftpl", {
      resource_group_name  = var.resource_group_name
      vsocket_primary_name = local.vsocket_primary_name_local
    })
  }

  depends_on = [
    terraform_data.run_command_ha_secondary
  ]
}

# Reboot Secondary vSocket
resource "terraform_data" "reboot_vsocket_secondary" {
  provisioner "local-exec" {
    # Templating the secondary restart command.
    command = templatefile("${path.module}/templates/reboot_vsocket_secondary.tftpl", {
      resource_group_name    = var.resource_group_name
      vsocket_secondary_name = local.vsocket_secondary_name_local
    })
  }

  depends_on = [
    terraform_data.run_command_ha_secondary,
    terraform_data.reboot_vsocket_primary
  ]
}

# Role assignments for secondary lan nic and subnet
#Temporary role assignments for primary
resource "azurerm_role_assignment" "primary_nic_ha_role" {
  principal_id         = azurerm_user_assigned_identity.CatoHaIdentity.principal_id
  role_definition_name = "Virtual Machine Contributor"
  scope                = "/subscriptions/${var.azure_subscription_id}/resourcegroups/${var.resource_group_name}/providers/Microsoft.Network/networkInterfaces/${data.azurerm_network_interface.lan_primary.name}"
  depends_on           = [azurerm_user_assigned_identity.CatoHaIdentity]
}

resource "azurerm_role_assignment" "secondary_nic_ha_role" {
  principal_id         = azurerm_user_assigned_identity.CatoHaIdentity.principal_id
  role_definition_name = "Virtual Machine Contributor"
  scope                = "/subscriptions/${var.azure_subscription_id}/resourcegroups/${var.resource_group_name}/providers/Microsoft.Network/networkInterfaces/${data.azurerm_network_interface.lan_secondary.name}"
  depends_on           = [azurerm_linux_virtual_machine.vsocket_secondary]
}

resource "azurerm_role_assignment" "lan-subnet-role" {
  principal_id         = azurerm_user_assigned_identity.CatoHaIdentity.principal_id
  role_definition_name = "Virtual Machine Contributor"
  scope                = "/subscriptions/${var.azure_subscription_id}/resourcegroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.vnet_name}/subnets/${var.lan_subnet_name}"
  depends_on           = [azurerm_user_assigned_identity.CatoHaIdentity]
}

# Time delay to allow for vsockets to upgrade
resource "time_sleep" "delay" {
  create_duration = "10s"
  depends_on      = [terraform_data.run_command_ha_secondary]
}

# Time delay to allow for vsockets HA to complete configuration
resource "time_sleep" "delay-ha" {
  create_duration = "75s"
  depends_on      = [terraform_data.reboot_vsocket_secondary]
}

# Allow vSocket to be disconnected to delete site
resource "time_sleep" "sleep_before_delete" {
  destroy_duration = "30s"
}

resource "cato_network_range" "routedAzure" {
  for_each        = var.routed_networks
  site_id         = cato_socket_site.azure-site.id
  name            = each.key
  range_type      = "Routed"
  gateway         = coalesce(each.value.gateway, local.lan_first_ip)
  interface_index = each.value.interface_index
  # Access attributes from the value object
  subnet            = each.value.subnet
  translated_subnet = var.enable_static_range_translation ? coalesce(each.value.translated_subnet, each.value.subnet) : null
  # This will be null if not defined, and the provider will ignore it.
}

# Update socket Bandwidth
resource "cato_wan_interface" "wan" {
  site_id              = cato_socket_site.azure-site.id
  interface_id         = "WAN1"
  name                 = "WAN 1"
  upstream_bandwidth   = var.upstream_bandwidth
  downstream_bandwidth = var.downstream_bandwidth
  role                 = "wan_1"
  precedence           = "ACTIVE"
}

# Cato license resource
resource "cato_license" "license" {
  depends_on = [terraform_data.reboot_vsocket_secondary]
  count      = var.license_id == null ? 0 : 1
  site_id    = cato_socket_site.azure-site.id
  license_id = var.license_id
  bw         = var.license_bw == null ? null : var.license_bw
}
