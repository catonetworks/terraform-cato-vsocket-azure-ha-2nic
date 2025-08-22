## The following attributes are exported:
output "wan_nic_name_primary" {
  description = "The name of the primary WAN network interface."
  value       = data.azurerm_network_interface.wan_primary.name
}

output "lan_nic_name_primary" {
  description = "The name of the primary LAN network interface."
  value       = data.azurerm_network_interface.lan_primary.name
}

output "wan_nic_name_secondary" {
  description = "The name of the secondary WAN network interface for HA."
  value       = data.azurerm_network_interface.wan_secondary.name
}

output "lan_nic_name_secondary" {
  description = "The name of the secondary LAN network interface for HA."
  value       = data.azurerm_network_interface.lan_secondary.name
}

# Cato Socket Site Outputs
output "cato_site_id" {
  description = "ID of the Cato Socket Site"
  value       = cato_socket_site.azure-site.id
}

output "cato_site_name" {
  description = "Name of the Cato Site"
  value       = cato_socket_site.azure-site.name
}

output "cato_primary_serial" {
  description = "Primary Cato Socket Serial Number"
  value       = try(local.primary_serial[0], "N/A")
}

output "cato_secondary_serial" {
  description = "Secondary Cato Socket Serial Number"
  value       = try(local.secondary_serial[0], "N/A")
}

# Network Interfaces Outputs
output "wan_primary_nic_id" {
  description = "ID of the WAN Primary Network Interface"
  value       = data.azurerm_network_interface.wan_primary.id
}

output "lan_primary_nic_id" {
  description = "ID of the LAN Primary Network Interface"
  value       = data.azurerm_network_interface.lan_primary.id
}

output "lan_primary_nic_mac_address" {
  description = "MAC of the LAN Primary Network Interface"
  value       = data.azurerm_network_interface.lannicmac.mac_address
}

output "wan_primary_nic_mac_address" {
  description = "MAC of the WAN Primary Network Interface"
  value       = data.azurerm_network_interface.wannicmac.mac_address
}

output "wan_secondary_nic_id" {
  description = "ID of the WAN Secondary Network Interface"
  value       = data.azurerm_network_interface.wan_secondary.id
}

output "lan_secondary_nic_id" {
  description = "ID of the LAN Secondary Network Interface"
  value       = data.azurerm_network_interface.lan_secondary.id
}

# Virtual Machine Outputs
output "vsocket_primary_vm_id" {
  description = "ID of the Primary vSocket Virtual Machine"
  value       = azurerm_linux_virtual_machine.vsocket_primary.id
}

output "vsocket_primary_vm_name" {
  description = "Name of the Primary vSocket Virtual Machine"
  value       = local.vsocket_primary_name_local
}

output "lan_secondary_nic_mac_address" {
  description = "MAC of the LAN Secondary Network Interface"
  value       = data.azurerm_network_interface.lannicmac-2.mac_address
}

output "wan_secondary_nic_mac_address" {
  description = "MAC of the WAN Secondary Network Interface"
  value       = data.azurerm_network_interface.wannicmac-2.mac_address
}

output "vsocket_secondary_vm_id" {
  description = "ID of the Secondary vSocket Virtual Machine"
  value       = azurerm_linux_virtual_machine.vsocket_secondary.id
}

output "vsocket_secondary_vm_name" {
  description = "Name of the Secondary vSocket Virtual Machine"
  value       = local.vsocket_secondary_name_local
}

# User Assigned Identity
output "ha_identity_id" {
  description = "ID of the User Assigned Identity for HA"
  value       = azurerm_user_assigned_identity.CatoHaIdentity.id
}

output "ha_identity_principal_id" {
  description = "Principal ID of the HA Identity"
  value       = azurerm_user_assigned_identity.CatoHaIdentity.principal_id
}

# Role Assignments Outputs
output "primary_nic_role_assignment_id" {
  description = "Role Assignment ID for the Primary NIC"
  value       = azurerm_role_assignment.primary_nic_ha_role.id
}

output "secondary_nic_role_assignment_id" {
  description = "Role Assignment ID for the Secondary NIC"
  value       = azurerm_role_assignment.secondary_nic_ha_role.id
}

output "lan_subnet_role_assignment_id" {
  description = "Role Assignment ID for the LAN Subnet"
  value       = azurerm_role_assignment.lan-subnet-role.id
}

# Reboot Status Outputs
output "vsocket_primary_reboot_status" {
  description = "Status of the Primary vSocket VM Reboot"
  value       = "Reboot triggered via Terraform"
  depends_on  = [terraform_data.reboot_vsocket_primary]
}

output "vsocket_secondary_reboot_status" {
  description = "Status of the Secondary vSocket VM Reboot"
  value       = "Reboot triggered via Terraform"
  depends_on  = [terraform_data.reboot_vsocket_secondary]
}

output "cato_license_site" {
  value = var.license_id == null ? null : {
    id           = cato_license.license[0].id
    license_id   = cato_license.license[0].license_id
    license_info = cato_license.license[0].license_info
    site_id      = cato_license.license[0].site_id
  }
}