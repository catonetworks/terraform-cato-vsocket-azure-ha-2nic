locals {
  primary_serial                    = [for s in data.cato_accountSnapshotSite.azure-site.info.sockets : s.serial if s.is_primary == true]
  secondary_serial                  = [for s in data.cato_accountSnapshotSite.azure-site-secondary.info.sockets : s.serial if s.is_primary == false]
  lan_first_ip                      = cidrhost(var.subnet_range_lan, 1)
  vsocket_primary_name_local        = var.vsocket_primary_name != null ? var.vsocket_primary_name : "Cato-vSocket-Primary"
  vsocket_secondary_name_local      = var.vsocket_secondary_name != null ? var.vsocket_secondary_name : "Cato-vSocket-Secondary"
  ha_identity_name_local            = var.ha_identity_name != null ? var.ha_identity_name : "CatoHaIdentity"
  vsocket_primary_disk_name_local   = var.vsocket_primary_disk_name != null ? var.vsocket_primary_disk_name : "vSocket-disk-primary"
  vsocket_secondary_disk_name_local = var.vsocket_secondary_disk_name != null ? var.vsocket_secondary_disk_name : "vSocket-disk-secondary"
}
