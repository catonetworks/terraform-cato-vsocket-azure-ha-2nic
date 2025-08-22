# CATO 2 NIC VSOCKET Azure HA Terraform module

Terraform module which creates an Azure Socket HA Site in the Cato Management Application (CMA) deploys a 2 nic primary and secondary virtual socket VM instance in Azure and configures them as HA, optionally updates sockets sites bandwidth, availability options and add routed ranges with names.

## NOTE
- The current API that the Cato provider is calling requires sequential execution. 
Cato recommends setting the value to 1. Example call: terraform apply -parallelism=1.
- VM size is Standard D2s v5 (2 vcpus, 8 GiB memory) for more efficient cost management.
- This module will look up the Cato Site Location information based on the Location of Azure specified.  If you would like to override this behavior, please leverage the below for help finding the correct values.
- For help with finding exact sytax to match site location for city, state_name, country_name and timezone, please refer to the [cato_siteLocation data source](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/data-sources/siteLocation).
- For help with finding a license id to assign, please refer to the [cato_licensingInfo data source](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/data-sources/licensingInfo).
- For Translated Ranges, "Enable Static Range Translation" but be enabled for more information please refer to [Configuring System Settings for the Account](https://support.catonetworks.com/hc/en-us/articles/4413280536849-Configuring-System-Settings-for-the-Account)


## Usage

```hcl
provider "azurerm" {
  subscription_id = var.azure_subscription_id
  features {}
}

provider "cato" {
  baseurl    = var.baseurl
  token      = var.token
  account_id = var.account_id
}

module "vsocket-azure-ha-2nic" {
  source                  = "catonetworks/terraform-cato-vsocket-azure-ha-2nic"
  token                   = var.token
  account_id              = var.account_id
  azure_subscription_id   = var.azure_subscription_id
  baseurl                 = var.baseurl
  location                = "West Europe"
  vnet_name               = "test-vnet"
  resource_group_name     = "test-rg"
  lan_subnet_name         = null    
  wan_nic_name_primary    = "wan-nic-primary"
  lan_nic_name_primary    = "lan-nic-primary"
  wan_nic_name_secondary  = "wan-nic-secondary"
  lan_nic_name_secondary  = "lan-nic-secondary"
  # ┌───── Optional Custom Naming for Azure Resources ─────┐
  vsocket_primary_name        = null              
  vsocket_secondary_name      = null                                         
  ha_identity_name            = null
  vsocket_primary_disk_name   = null
  vsocket_secondary_disk_name = null
  # └──────────────────────────────────────────────────────┘
  subnet_range_lan       = "10.113.3.128/25"
  floating_ip            = "10.113.3.137"
   # ┌───── Optional Availability configuration ─────┐
  vsocket_primary_zone   = "1"
  vsocket_secondary_zone = "2"                         # You cannot use Zones and Availability sets
  availability_set_id    = null
  # └────────────────────────────────────────────────┘
   
  enable_static_range_translation = false #set to true if the Account settings has been updated.
  routed_networks = {
    "Peered-VNET-1" = {
      subnet = "10.100.1.0/24"
      # interface_index is omitted, so it will default to "LAN1".
    }
    "On-Prem-Network-With-NAT" = {
      subnet            = "192.168.51.0/24"
      translated_subnet = "10.250.3.0/24" # Example translated range, SRT Required, set 
      gateway = "192.168.51.254" # Overriding the default value of LAN1 LocalIP
    }
  }

  upstream_bandwidth    = 1000
  downstream_bandwidth  = 1000
  site_name             = "Your Site name here"
  site_description      = "Your description here"
  # Site location is Derived from Azure Region Location
  tags = {
    example_key = "example_value"
    terraform   = "true"
    git_repo    = "https://github.com/catonetworks/terraform-cato-vsocket-azure-ha-vnet-2nic"
  }
}
```

## Site Location Reference

For more information on site_location syntax, use the [Cato CLI](https://github.com/catonetworks/cato-cli) to lookup values.

```bash
$ pip3 install catocli
$ export CATO_TOKEN="your-api-token-here"
$ export CATO_ACCOUNT_ID="your-account-id"
$ catocli query siteLocation -h
$ catocli query siteLocation '{"filters":[{"search": "San Diego","field":"city","operation":"exact"}]}' -p
```

## Authors

Module is maintained by [Cato Networks](https://github.com/catonetworks) with help from [these awesome contributors](https://github.com/catonetworks/terraform-cato-vsocket-azure-ha-vnet-2nic/graphs/contributors).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/catonetworks/terraform-cato-vsocket-azure-ha-vnet-2nic/tree/master/LICENSE) for full details.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.33.0 |
| <a name="requirement_cato"></a> [cato](#requirement\_cato) | >= 0.0.38 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.33.0 |
| <a name="provider_cato"></a> [cato](#provider\_cato) | >= 0.0.38 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_virtual_machine.vsocket_primary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_linux_virtual_machine.vsocket_secondary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_role_assignment.lan-subnet-role](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.primary_nic_ha_role](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.secondary_nic_ha_role](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_user_assigned_identity.CatoHaIdentity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_virtual_machine_extension.vsocket-custom-script-primary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.vsocket-custom-script-secondary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [cato_license.license](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/license) | resource |
| [cato_network_range.routedAzure](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/network_range) | resource |
| [cato_socket_site.azure-site](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/socket_site) | resource |
| [cato_wan_interface.wan](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/wan_interface) | resource |
| [random_string.vsocket-random-password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_string.vsocket-random-username](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [terraform_data.configure_secondary_azure_vsocket](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.reboot_vsocket_primary](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.reboot_vsocket_secondary](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.run_command_ha_primary](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.run_command_ha_secondary](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [time_sleep.delay](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.delay-ha](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.sleep_300_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.sleep_30_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.sleep_5_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.sleep_5_seconds-2](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.sleep_before_delete](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [azurerm_network_interface.lan_primary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_interface) | data source |
| [azurerm_network_interface.lan_secondary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_interface) | data source |
| [azurerm_network_interface.lannicmac](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_interface) | data source |
| [azurerm_network_interface.lannicmac-2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_interface) | data source |
| [azurerm_network_interface.wan_primary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_interface) | data source |
| [azurerm_network_interface.wan_secondary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_interface) | data source |
| [azurerm_network_interface.wannicmac](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_interface) | data source |
| [azurerm_network_interface.wannicmac-2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_interface) | data source |
| [azurerm_resource_group.data-azure-rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [cato_accountSnapshotSite.azure-site](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/data-sources/accountSnapshotSite) | data source |
| [cato_accountSnapshotSite.azure-site-2](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/data-sources/accountSnapshotSite) | data source |
| [cato_accountSnapshotSite.azure-site-secondary](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/data-sources/accountSnapshotSite) | data source |
| [cato_siteLocation.site_location](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/data-sources/siteLocation) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Account ID used for the Cato Networks integration. | `number` | `null` | no |
| <a name="input_availability_set_id"></a> [availability\_set\_id](#input\_availability\_set\_id) | Availability set ID | `string` | `null` | no |
| <a name="input_azure_subscription_id"></a> [azure\_subscription\_id](#input\_azure\_subscription\_id) | The Azure Subscription ID where the resources will be created. Example: 00000000-0000-0000-0000-000000000000 | `string` | n/a | yes |
| <a name="input_baseurl"></a> [baseurl](#input\_baseurl) | Base URL for the Cato Networks API. | `string` | `"https://api.catonetworks.com/api/v1/graphql2"` | no |
| <a name="input_commands"></a> [commands](#input\_commands) | n/a | `list(string)` | <pre>[<br/>  "rm /cato/deviceid.txt",<br/>  "rm /cato/socket/configuration/socket_registration.json",<br/>  "nohup /cato/socket/run_socket_daemon.sh &"<br/>]</pre> | no |
| <a name="input_downstream_bandwidth"></a> [downstream\_bandwidth](#input\_downstream\_bandwidth) | Sockets downstream interface WAN Bandwidth in Mbps | `string` | `"null"` | no |
| <a name="input_enable_boot_diagnostics"></a> [enable\_boot\_diagnostics](#input\_enable\_boot\_diagnostics) | If true, enables boot diagnostics with a managed storage account. If false, disables it. | `bool` | `true` | no |
| <a name="input_enable_static_range_translation"></a> [enable\_static\_range\_translation](#input\_enable\_static\_range\_translation) | Enables the ability to use translated ranges | `string` | `false` | no |
| <a name="input_floating_ip"></a> [floating\_ip](#input\_floating\_ip) | Floating IP Address for the vSocket | `string` | `null` | no |
| <a name="input_ha_identity_name"></a> [ha\_identity\_name](#input\_ha\_identity\_name) | Optional override name for the Cato HA Identity | `string` | `null` | no |
| <a name="input_lan_nic_name_primary"></a> [lan\_nic\_name\_primary](#input\_lan\_nic\_name\_primary) | The name of the primary LAN network interface. | `string` | n/a | yes |
| <a name="input_lan_nic_name_secondary"></a> [lan\_nic\_name\_secondary](#input\_lan\_nic\_name\_secondary) | The name of the secondary LAN network interface. | `string` | n/a | yes |
| <a name="input_lan_subnet_name"></a> [lan\_subnet\_name](#input\_lan\_subnet\_name) | The name of the LAN subnet within the specified VNET. | `string` | n/a | yes |
| <a name="input_license_bw"></a> [license\_bw](#input\_license\_bw) | The license bandwidth number for the cato site, specifying bandwidth ONLY applies for pooled licenses.  For a standard site license that is not pooled, leave this value null. Must be a number greater than 0 and an increment of 10. | `string` | `null` | no |
| <a name="input_license_id"></a> [license\_id](#input\_license\_id) | The license ID for the Cato vSocket of license type CATO\_SITE, CATO\_SSE\_SITE, CATO\_PB, CATO\_PB\_SSE.  Example License ID value: 'abcde123-abcd-1234-abcd-abcde1234567'.  Note that licenses are for commercial accounts, and not supported for trial accounts. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | `null` | no |
| <a name="input_native_network_range"></a> [native\_network\_range](#input\_native\_network\_range) | Cato Native Network Range for the Site | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group name required if you want to deploy into existing Resource group | `string` | n/a | yes |
| <a name="input_resource_prefix_name"></a> [resource\_prefix\_name](#input\_resource\_prefix\_name) | Prefix used for Azure resource names. Must conform to Azure naming restrictions. | `string` | `null` | no |
| <a name="input_routed_networks"></a> [routed\_networks](#input\_routed\_networks) | A map of routed networks to be accessed behind the vSocket site.<br/>  - The key is the logical name for the network.<br/>  - The value is an object containing:<br/>    - "subnet" (string, required): The actual CIDR range of the network.<br/>    - "translated\_subnet" (string, optional): The NATed CIDR range if translation is used.<br/>  Example: <br/>  routed\_networks = {<br/>    "Peered-VNET-1" = {<br/>      subnet = "10.100.1.0/24"<br/>    }<br/>    "On-Prem-Network-NAT" = {<br/>      subnet            = "192.168.51.0/24"<br/>      translated\_subnet = "10.200.1.0/24"<br/>    }<br/>  } | <pre>map(object({<br/>    subnet            = string<br/>    translated_subnet = optional(string)<br/>    gateway           = optional(string)<br/>    interface_index   = optional(string, "LAN1")<br/>  }))</pre> | `{}` | no |
| <a name="input_site_description"></a> [site\_description](#input\_site\_description) | Description of the vsocket site | `string` | n/a | yes |
| <a name="input_site_location"></a> [site\_location](#input\_site\_location) | Site location which is used by the Cato Socket to connect to the closest Cato PoP. If not specified, the location will be derived from the Azure region dynamicaly. | <pre>object({<br/>    city         = string<br/>    country_code = string<br/>    state_code   = string<br/>    timezone     = string<br/>  })</pre> | <pre>{<br/>  "city": null,<br/>  "country_code": null,<br/>  "state_code": null,<br/>  "timezone": null<br/>}</pre> | no |
| <a name="input_site_name"></a> [site\_name](#input\_site\_name) | Name of the vsocket site | `string` | n/a | yes |
| <a name="input_site_type"></a> [site\_type](#input\_site\_type) | The type of the site | `string` | `"CLOUD_DC"` | no |
| <a name="input_subnet_range_lan"></a> [subnet\_range\_lan](#input\_subnet\_range\_lan) | LAN subnet prefix in CIDR notation (e.g., X.X.X.X/X). | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A Map of Strings to describe infrastructure | `map(string)` | `{}` | no |
| <a name="input_token"></a> [token](#input\_token) | API token used to authenticate with the Cato Networks API. | `string` | n/a | yes |
| <a name="input_upstream_bandwidth"></a> [upstream\_bandwidth](#input\_upstream\_bandwidth) | Sockets upstream interface WAN Bandwidth in Mbps | `string` | `"null"` | no |
| <a name="input_vm_image_config"></a> [vm\_image\_config](#input\_vm\_image\_config) | Configuration for the Marketplace image, including plan and source image reference. | <pre>object({<br/>    publisher = string<br/>    offer     = string<br/>    product   = string<br/>    sku       = string<br/>    version   = string<br/>  })</pre> | <pre>{<br/>  "offer": "cato_socket",<br/>  "product": "cato_socket",<br/>  "publisher": "catonetworks",<br/>  "sku": "public-cato-socket",<br/>  "version": "23.0.19605"<br/>}</pre> | no |
| <a name="input_vm_os_disk_config"></a> [vm\_os\_disk\_config](#input\_vm\_os\_disk\_config) | Configuration for the Virtual Machine's OS disk. | <pre>object({<br/>    name_suffix          = string<br/>    caching              = string<br/>    storage_account_type = string<br/>    disk_size_gb         = number<br/>  })</pre> | <pre>{<br/>  "caching": "ReadWrite",<br/>  "disk_size_gb": 8,<br/>  "name_suffix": "vSocket-disk-primary",<br/>  "storage_account_type": "Standard_LRS"<br/>}</pre> | no |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | (Required) Specifies the size of the Virtual Machine. See Azure VM Naming Conventions: https://learn.microsoft.com/en-us/azure/virtual-machines/vm-naming-conventions | `string` | `"Standard_D2s_v5"` | no |
| <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name) | VNET Name required if you want to deploy into existing VNET | `string` | n/a | yes |
| <a name="input_vsocket_primary_disk_name"></a> [vsocket\_primary\_disk\_name](#input\_vsocket\_primary\_disk\_name) | Optional override name for the primary vSocket Disk | `string` | `null` | no |
| <a name="input_vsocket_primary_name"></a> [vsocket\_primary\_name](#input\_vsocket\_primary\_name) | Optional override name for the primary vSocket | `string` | `null` | no |
| <a name="input_vsocket_primary_zone"></a> [vsocket\_primary\_zone](#input\_vsocket\_primary\_zone) | Primary vsocket Availability Zone | `string` | `null` | no |
| <a name="input_vsocket_secondary_disk_name"></a> [vsocket\_secondary\_disk\_name](#input\_vsocket\_secondary\_disk\_name) | Optional override name for the secondary vSocket Disk | `string` | `null` | no |
| <a name="input_vsocket_secondary_name"></a> [vsocket\_secondary\_name](#input\_vsocket\_secondary\_name) | Optional override name for the secondary vSocket | `string` | `null` | no |
| <a name="input_vsocket_secondary_zone"></a> [vsocket\_secondary\_zone](#input\_vsocket\_secondary\_zone) | Secondary vsocket Availability Zone | `string` | `null` | no |
| <a name="input_wan_nic_name_primary"></a> [wan\_nic\_name\_primary](#input\_wan\_nic\_name\_primary) | The name of the primary WAN network interface. | `string` | n/a | yes |
| <a name="input_wan_nic_name_secondary"></a> [wan\_nic\_name\_secondary](#input\_wan\_nic\_name\_secondary) | The name of the secondary WAN network interface. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cato_license_site"></a> [cato\_license\_site](#output\_cato\_license\_site) | n/a |
| <a name="output_cato_primary_serial"></a> [cato\_primary\_serial](#output\_cato\_primary\_serial) | Primary Cato Socket Serial Number |
| <a name="output_cato_secondary_serial"></a> [cato\_secondary\_serial](#output\_cato\_secondary\_serial) | Secondary Cato Socket Serial Number |
| <a name="output_cato_site_id"></a> [cato\_site\_id](#output\_cato\_site\_id) | ID of the Cato Socket Site |
| <a name="output_cato_site_name"></a> [cato\_site\_name](#output\_cato\_site\_name) | Name of the Cato Site |
| <a name="output_ha_identity_id"></a> [ha\_identity\_id](#output\_ha\_identity\_id) | ID of the User Assigned Identity for HA |
| <a name="output_ha_identity_principal_id"></a> [ha\_identity\_principal\_id](#output\_ha\_identity\_principal\_id) | Principal ID of the HA Identity |
| <a name="output_lan_nic_name_primary"></a> [lan\_nic\_name\_primary](#output\_lan\_nic\_name\_primary) | The name of the primary LAN network interface. |
| <a name="output_lan_nic_name_secondary"></a> [lan\_nic\_name\_secondary](#output\_lan\_nic\_name\_secondary) | The name of the secondary LAN network interface for HA. |
| <a name="output_lan_primary_nic_id"></a> [lan\_primary\_nic\_id](#output\_lan\_primary\_nic\_id) | ID of the LAN Primary Network Interface |
| <a name="output_lan_primary_nic_mac_address"></a> [lan\_primary\_nic\_mac\_address](#output\_lan\_primary\_nic\_mac\_address) | MAC of the LAN Primary Network Interface |
| <a name="output_lan_secondary_nic_id"></a> [lan\_secondary\_nic\_id](#output\_lan\_secondary\_nic\_id) | ID of the LAN Secondary Network Interface |
| <a name="output_lan_secondary_nic_mac_address"></a> [lan\_secondary\_nic\_mac\_address](#output\_lan\_secondary\_nic\_mac\_address) | MAC of the LAN Secondary Network Interface |
| <a name="output_lan_subnet_role_assignment_id"></a> [lan\_subnet\_role\_assignment\_id](#output\_lan\_subnet\_role\_assignment\_id) | Role Assignment ID for the LAN Subnet |
| <a name="output_primary_nic_role_assignment_id"></a> [primary\_nic\_role\_assignment\_id](#output\_primary\_nic\_role\_assignment\_id) | Role Assignment ID for the Primary NIC |
| <a name="output_secondary_nic_role_assignment_id"></a> [secondary\_nic\_role\_assignment\_id](#output\_secondary\_nic\_role\_assignment\_id) | Role Assignment ID for the Secondary NIC |
| <a name="output_site_location"></a> [site\_location](#output\_site\_location) | n/a |
| <a name="output_vsocket_primary_reboot_status"></a> [vsocket\_primary\_reboot\_status](#output\_vsocket\_primary\_reboot\_status) | Status of the Primary vSocket VM Reboot |
| <a name="output_vsocket_primary_vm_id"></a> [vsocket\_primary\_vm\_id](#output\_vsocket\_primary\_vm\_id) | ID of the Primary vSocket Virtual Machine |
| <a name="output_vsocket_primary_vm_name"></a> [vsocket\_primary\_vm\_name](#output\_vsocket\_primary\_vm\_name) | Name of the Primary vSocket Virtual Machine |
| <a name="output_vsocket_secondary_reboot_status"></a> [vsocket\_secondary\_reboot\_status](#output\_vsocket\_secondary\_reboot\_status) | Status of the Secondary vSocket VM Reboot |
| <a name="output_vsocket_secondary_vm_id"></a> [vsocket\_secondary\_vm\_id](#output\_vsocket\_secondary\_vm\_id) | ID of the Secondary vSocket Virtual Machine |
| <a name="output_vsocket_secondary_vm_name"></a> [vsocket\_secondary\_vm\_name](#output\_vsocket\_secondary\_vm\_name) | Name of the Secondary vSocket Virtual Machine |
| <a name="output_wan_nic_name_primary"></a> [wan\_nic\_name\_primary](#output\_wan\_nic\_name\_primary) | The name of the primary WAN network interface. |
| <a name="output_wan_nic_name_secondary"></a> [wan\_nic\_name\_secondary](#output\_wan\_nic\_name\_secondary) | The name of the secondary WAN network interface for HA. |
| <a name="output_wan_primary_nic_id"></a> [wan\_primary\_nic\_id](#output\_wan\_primary\_nic\_id) | ID of the WAN Primary Network Interface |
| <a name="output_wan_primary_nic_mac_address"></a> [wan\_primary\_nic\_mac\_address](#output\_wan\_primary\_nic\_mac\_address) | MAC of the WAN Primary Network Interface |
| <a name="output_wan_secondary_nic_id"></a> [wan\_secondary\_nic\_id](#output\_wan\_secondary\_nic\_id) | ID of the WAN Secondary Network Interface |
| <a name="output_wan_secondary_nic_mac_address"></a> [wan\_secondary\_nic\_mac\_address](#output\_wan\_secondary\_nic\_mac\_address) | MAC of the WAN Secondary Network Interface |
<!-- END_TF_DOCS -->