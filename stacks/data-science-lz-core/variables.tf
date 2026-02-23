variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Spoke resource group name."
}

variable "tags" {
  type        = map(string)
  description = "Common tags."
  default     = {}
}

variable "hub_subscription_id" {
  type        = string
  description = "Hub subscription id (optional). Leave empty if hub resources are in the same subscription."
  default     = ""
}

variable "allow_resource_group_destroy" {
  type        = bool
  description = "If true, resource group is not protected by prevent_destroy."
  default     = false
}

variable "vnet" {
  type = object({
    name          = string
    address_space = list(string)
  })
}

variable "subnets" {
  type = map(object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegations = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })), [])
    private_endpoint_network_policies             = optional(string, "Disabled")
    private_link_service_network_policies_enabled = optional(string, "Enabled")
  }))
}

variable "hub_connectivity" {
  type = object({
    enabled           = bool
    connectivity_type = string

    hub_vnet_id             = optional(string, "")
    hub_vnet_name           = optional(string, "")
    hub_resource_group_name = optional(string, "")
    manage_hub_side_peering = optional(bool, false)

    virtual_hub_id             = optional(string, "")
    virtual_hub_route_table_id = optional(string, "")
    propagated_route_table_ids = optional(list(string), [])
    labels                     = optional(list(string), [])
  })
}

variable "private_dns" {
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
  type = object({
    enabled                       = bool
    name                          = optional(string, "")
    sku_name                      = optional(string, "standard")
    purge_protection_enabled      = optional(bool, true)
    soft_delete_retention_days    = optional(number, 7)
    public_network_access_enabled = optional(bool, false)
  })
  default = {
    enabled = false
    name    = ""
  }
}

variable "log_analytics" {
  type = object({
    enabled                    = bool
    name                       = optional(string, "")
    sku                        = optional(string, "PerGB2018")
    retention_in_days          = optional(number, 30)
    internet_ingestion_enabled = optional(bool, true)
    internet_query_enabled     = optional(bool, true)
  })
  default = {
    enabled = false
    name    = ""
  }
}

variable "application_insights" {
  type = object({
    enabled          = bool
    name             = optional(string, "")
    application_type = optional(string, "web")
  })
  default = {
    enabled = false
    name    = ""
  }
}

variable "storage_account" {
  type = object({
    enabled                         = bool
    name                            = optional(string, "")
    account_tier                    = optional(string, "Standard")
    account_replication_type        = optional(string, "LRS")
    min_tls_version                 = optional(string, "TLS1_2")
    public_network_access_enabled   = optional(bool, false)
    allow_nested_items_to_be_public = optional(bool, false)
    shared_access_key_enabled       = optional(bool, true)
  })
  default = {
    enabled = false
    name    = ""
  }
}

variable "container_registry" {
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
}
