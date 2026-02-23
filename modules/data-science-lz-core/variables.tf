variable "location" {
  type        = string
  description = "Azure region for the landing zone resources."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name for the landing zone (spoke) resources."
  validation {
    condition     = can(regex("^rg-[a-z0-9]+-(dev|test|qa|uat|stage|prod|dr|poc|sand)-[a-z0-9]+-[a-z0-9]+$", var.resource_group_name))
    error_message = "resource_group_name must follow: rg-subname-env-projectname-location (lowercase, hyphen-separated)."
  }
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources."
  default     = {}
}

variable "allow_resource_group_destroy" {
  type        = bool
  description = "If true, RG is not protected by prevent_destroy. Default false (protected)."
  default     = false
}

variable "vnet" {
  description = "Spoke VNet configuration."
  type = object({
    name          = string
    address_space = list(string)
  })

  validation {
    condition     = can(regex("^vnet-[a-z0-9]+-(dev|test|qa|uat|stage|prod|dr|poc|sand)-[a-z0-9]+-[a-z0-9]+$", var.vnet.name))
    error_message = "vnet.name must follow: vnet-subname-env-projectname-location (lowercase, hyphen-separated)."
  }
}

variable "subnets" {
  description = "Subnet map. Keys are logical labels; values define subnet settings."
  type = map(object({
    name                                      = string
    address_prefixes                          = list(string)
    service_endpoints                         = optional(list(string), [])
    delegations                               = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })), [])

    # AzureRM v4 uses string policies on subnets ("Enabled"/"Disabled").
    private_endpoint_network_policies                 = optional(string, "Disabled")
    private_link_service_network_policies_enabled     = optional(string, "Enabled")
  }))

  validation {
    condition     = alltrue([for s in values(var.subnets) : can(regex("^snet-[a-z0-9]+-(dev|test|qa|uat|stage|prod|dr|poc|sand)-[a-z0-9]+-[a-z0-9]+$", s.name))])
    error_message = "All subnet names must follow: snet-subname-env-projectname-location (lowercase, hyphen-separated)."
  }
}

variable "hub_connectivity" {
  description = "Hub connectivity settings. Choose vnet_peering or vwan_virtual_hub."
  type = object({
    enabled                 = bool
    connectivity_type       = string # \"vnet_peering\" | \"vwan_virtual_hub\"

    # Peering inputs
    hub_vnet_id             = optional(string, "")
    hub_vnet_name           = optional(string, "")
    hub_resource_group_name = optional(string, "")
    manage_hub_side_peering = optional(bool, false)

    # vWAN inputs
    virtual_hub_id                  = optional(string, "")
    virtual_hub_route_table_id      = optional(string, "")
    propagated_route_table_ids      = optional(list(string), [])
    labels                          = optional(list(string), [])
  })

  validation {
    condition     = contains(["vnet_peering", "vwan_virtual_hub"], var.hub_connectivity.connectivity_type)
    error_message = "hub_connectivity.connectivity_type must be one of: vnet_peering, vwan_virtual_hub."
  }
}

variable "private_dns" {
  description = "Link spoke VNet to hub-managed Private DNS zones (cross-subscription supported via provider alias)."
  type = object({
    enabled                 = bool
    hub_private_dns_rg_name = optional(string, "")
    zone_names              = optional(list(string), [])
  })
  default = {
    enabled                 = false
    hub_private_dns_rg_name = ""
    zone_names              = []
  }
}

variable "key_vault" {
  description = "Baseline Key Vault configuration (optional)."
  type = object({
    enabled                        = bool
    name                           = optional(string, "")
    sku_name                       = optional(string, "standard")
    purge_protection_enabled       = optional(bool, true)
    soft_delete_retention_days     = optional(number, 7)
    public_network_access_enabled  = optional(bool, false)
  })
  default = {
    enabled = false
    name    = ""
  }
}

variable "log_analytics" {
  description = "Baseline Log Analytics workspace (optional)."
  type = object({
    enabled                       = bool
    name                          = optional(string, "")
    sku                           = optional(string, "PerGB2018")
    retention_in_days             = optional(number, 30)
    internet_ingestion_enabled    = optional(bool, true)
    internet_query_enabled        = optional(bool, true)
  })
  default = {
    enabled = false
    name    = ""
  }
}

variable "application_insights" {
  description = "Baseline Application Insights (optional). Typically used by AML and apps."
  type = object({
    enabled                     = bool
    name                        = optional(string, "")
    application_type            = optional(string, "web")
  })
  default = {
    enabled = false
    name    = ""
  }
}

variable "storage_account" {
  description = "Baseline Storage Account (optional). NOTE: storage account name cannot contain hyphens."
  type = object({
    enabled                        = bool
    name                           = optional(string, "")
    account_tier                   = optional(string, "Standard")
    account_replication_type       = optional(string, "LRS")
    min_tls_version                = optional(string, "TLS1_2")
    public_network_access_enabled  = optional(bool, false)
    allow_nested_items_to_be_public = optional(bool, false)
    shared_access_key_enabled      = optional(bool, true)
  })
  default = {
    enabled = false
    name    = ""
  }

  validation {
    condition = (
      var.storage_account.enabled == false
      || (var.storage_account.enabled == true
          && var.storage_account.name != ""
          && can(regex("^[a-z0-9]{3,24}$", var.storage_account.name)))
    )
    error_message = "When storage_account.enabled is true, storage_account.name must be 3-24 chars, lowercase letters/numbers only (no hyphens)."
  }
}

variable "container_registry" {
  description = "Baseline Azure Container Registry (optional). NOTE: ACR name cannot contain hyphens."
  type = object({
    enabled                       = bool
    name                          = optional(string, "")
    sku                           = optional(string, "Standard")
    admin_enabled                 = optional(bool, false)
    public_network_access_enabled = optional(bool, true)
  })
  default = {
    enabled = false
    name    = ""
  }

  validation {
    condition = (
      var.container_registry.enabled == false
      || (var.container_registry.enabled == true
          && var.container_registry.name != ""
          && can(regex("^[a-zA-Z0-9]{5,50}$", var.container_registry.name)))
    )
    error_message = "When container_registry.enabled is true, container_registry.name must be 5-50 chars, alphanumeric only (no hyphens)."
  }
}
