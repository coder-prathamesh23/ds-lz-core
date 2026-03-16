variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Landing zone resource group name."
}

variable "resource_group_id" {
  type        = string
  description = "Landing zone resource group ID (resolved by the calling stack)."
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to resources."
  default     = {}
}

variable "spoke_vnet_id" {
  type        = string
  description = "Spoke VNet ID resolved by the base stack."
}

variable "workload_subnet_id" {
  type        = string
  description = "Workload subnet ID resolved by the base stack."
}

variable "private_endpoints_subnet_id" {
  type        = string
  description = "Private endpoints subnet ID resolved by the base stack."
}

variable "key_vault" {
  description = "Optional baseline Key Vault."
  type = object({
    enabled                       = bool
    name                          = string
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
  description = "Optional baseline Log Analytics workspace."
  type = object({
    enabled                    = bool
    name                       = string
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
  description = "Optional baseline Application Insights."
  type = object({
    enabled          = bool
    name             = string
    application_type = optional(string, "web")
  })
  default = {
    enabled = false
    name    = ""
  }
}

variable "storage_account" {
  description = "Optional baseline Storage Account. Storage account names must be 3-24 lowercase alphanumeric characters."
  type = object({
    enabled                         = bool
    name                            = string
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

  validation {
    condition = (
      var.storage_account.enabled == false
      || (
        var.storage_account.enabled == true
        && var.storage_account.name != ""
        && can(regex("^[a-z0-9]{3,24}$", var.storage_account.name))
      )
    )
    error_message = "When storage_account.enabled is true, storage_account.name must be 3-24 chars, lowercase letters/numbers only."
  }
}

variable "container_registry" {
  description = "Optional baseline Azure Container Registry. ACR names must be 5-50 alphanumeric characters. Premium is recommended when private endpoints are planned later."
  type = object({
    enabled                       = bool
    name                          = string
    sku                           = optional(string, "Premium")
    admin_enabled                 = optional(bool, true)
    public_network_access_enabled = optional(bool, false)
  })
  default = {
    enabled = false
    name    = ""
  }

  validation {
    condition = (
      var.container_registry.enabled == false
      || (
        var.container_registry.enabled == true
        && var.container_registry.name != ""
        && can(regex("^[a-zA-Z0-9]{5,50}$", var.container_registry.name))
      )
    )
    error_message = "When container_registry.enabled is true, container_registry.name must be 5-50 chars, alphanumeric only."
  }
}
