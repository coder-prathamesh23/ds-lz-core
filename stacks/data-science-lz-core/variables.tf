variable "location" {
  type        = string
  description = "Azure region for resources."
}

variable "resource_group_name" {
  type        = string
  description = "Landing zone resource group name."
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources."
  default     = {}
}

variable "allow_resource_group_destroy" {
  type        = bool
  description = "If true, the landing zone resource group is not protected by prevent_destroy."
  default     = false
}

variable "spoke_subscription_id" {
  type        = string
  description = "Subscription ID where the landing zone (spoke) resources are deployed."
}

variable "hub_subscription_id" {
  type        = string
  description = "Subscription ID where the hub Virtual Hub resources live. Use the same value as spoke_subscription_id if hub and spoke are in the same subscription."
}

variable "network_mode" {
  description = "Controls whether the spoke network is created by this stack or referenced via data sources. Allowed values: create, import."
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "import"], var.network_mode)
    error_message = "network_mode must be one of: create, import."
  }
}

variable "spoke_vnet" {
  description = "Existing spoke VNet reference (import mode). Provide either id OR (name + resource_group_name)."
  type = object({
    id                  = optional(string)
    name                = optional(string)
    resource_group_name = optional(string)
  })
  default = {}
}

variable "workload_subnet" {
  description = "Existing workload subnet reference (import mode). Provide either id OR (name + vnet/rg resolvable)."
  type = object({
    id                   = optional(string)
    name                 = optional(string)
    virtual_network_name = optional(string)
    resource_group_name  = optional(string)
  })
  default = {}
}

variable "private_endpoints_subnet" {
  description = "Existing private endpoints subnet reference (import mode). Provide either id OR (name + vnet/rg resolvable)."
  type = object({
    id                   = optional(string)
    name                 = optional(string)
    virtual_network_name = optional(string)
    resource_group_name  = optional(string)
  })
  default = {}
}

variable "spoke_vnet_name" {
  description = "Spoke VNet name (create mode)."
  type        = string
  default     = ""
}

variable "spoke_vnet_address_space" {
  description = "Spoke VNet address space (create mode)."
  type        = list(string)
  default     = []
}

variable "spoke_vnet_dns_servers" {
  description = "Custom DNS servers for the spoke VNet. Leave empty to use Azure defaults."
  type        = list(string)
  default     = []
}

variable "workload_subnet_name" {
  description = "Workload subnet name (create mode)."
  type        = string
  default     = ""
}

variable "workload_subnet_address_prefixes" {
  description = "Workload subnet address prefixes (create mode)."
  type        = list(string)
  default     = []
}

variable "private_endpoints_subnet_name" {
  description = "Private endpoints subnet name (create mode)."
  type        = string
  default     = ""
}

variable "private_endpoints_subnet_address_prefixes" {
  description = "Private endpoints subnet address prefixes (create mode)."
  type        = list(string)
  default     = []
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
  description = "Optional baseline Storage Account."
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
}

variable "container_registry" {
  description = "Optional baseline Azure Container Registry. Premium is recommended when future private endpoints are expected."
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
}

variable "enable_vhub_connection" {
  type        = bool
  description = "If true, create vHub to spoke VNet connection."
  default     = false
}

variable "hub_virtual_hub_id" {
  type        = string
  description = "Virtual Hub resource ID to connect the spoke VNet to."
  default     = ""
}

variable "vhub_connection_name" {
  type        = string
  description = "Name of the vHub connection resource."
  default     = "conn-spoke-to-vhub"
}

variable "internet_security_enabled" {
  type        = bool
  description = "Whether Internet Security is enabled on the vHub connection."
  default     = true
}
