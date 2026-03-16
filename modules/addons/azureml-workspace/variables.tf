variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name where the AML workspace will be created."
}

variable "tags" {
  type        = map(string)
  description = "Common tags."
  default     = {}
}

variable "ml_workspace_name" {
  type        = string
  description = "Azure Machine Learning workspace name."
}

variable "sku_name" {
  type        = string
  description = "AML workspace SKU."
  default     = "Basic"
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Whether public network access is enabled for the AML workspace."
  default     = false
}

variable "high_business_impact" {
  type        = bool
  description = "Set to true for HBI workspaces."
  default     = false
}

variable "managed_network" {
  description = "AML workspace managed network configuration."
  type = object({
    isolation_mode                = optional(string, "AllowOnlyApprovedOutbound")
    provision_on_creation_enabled = optional(bool, true)
  })
  default = {
    isolation_mode                = "AllowOnlyApprovedOutbound"
    provision_on_creation_enabled = true
  }

  validation {
    condition = contains(
      ["Disabled", "AllowOnlyApprovedOutbound", "AllowInternetOutbound"],
      try(var.managed_network.isolation_mode, "AllowOnlyApprovedOutbound")
    )
    error_message = "managed_network.isolation_mode must be Disabled, AllowOnlyApprovedOutbound, or AllowInternetOutbound."
  }
}

variable "application_insights_id" {
  type        = string
  description = "Application Insights resource ID."
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault resource ID."
}

variable "storage_account_id" {
  type        = string
  description = "AML-owned storage account resource ID."
}

variable "container_registry_id" {
  type        = string
  description = "AML-owned ACR resource ID."
  default     = ""
}

variable "container_registry_admin_enabled" {
  type        = bool
  description = "Whether admin access is enabled on the ACR associated to AML."
  default     = false
}

variable "spoke_vnet_id" {
  type        = string
  description = "Spoke VNet ID for downstream AML network-dependent components."
  default     = ""
}

variable "workload_subnet_id" {
  type        = string
  description = "Workload subnet ID for downstream AML network-dependent components."
  default     = ""
}

variable "private_endpoints_subnet_id" {
  type        = string
  description = "Private endpoints subnet ID used for AML workspace private endpoint."
  default     = ""
}

variable "enable_workspace_private_endpoint" {
  type        = bool
  description = "Whether to create a private endpoint for the AML workspace in the spoke VNet."
  default     = false
}

variable "workspace_private_endpoint_name" {
  type        = string
  description = "Optional explicit name for the AML workspace private endpoint."
  default     = ""
}

variable "workspace_private_dns_zone_ids" {
  type        = list(string)
  description = "Existing central Private DNS zone IDs for AML workspace private endpoint DNS integration."
  default     = []
}

variable "workspace_private_service_subresource_names" {
  type        = list(string)
  description = "Private Link subresource names for the AML workspace private endpoint."
  default     = ["amlworkspace"]
}

variable "aml_primary_outbound_rules" {
  description = "Managed outbound private endpoint rules from AML managed network to AML-owned dependencies."
  type = object({
    enable_storage              = optional(bool, true)
    storage_subresource_targets = optional(list(string), ["blob"])
    enable_key_vault            = optional(bool, true)
    enable_acr                  = optional(bool, true)
    acr_subresource_targets     = optional(list(string), ["registry"])
  })
  default = {
    enable_storage              = true
    storage_subresource_targets = ["blob"]
    enable_key_vault            = true
    enable_acr                  = true
    acr_subresource_targets     = ["registry"]
  }
}

variable "shared_storage" {
  description = "Separate shared storage account used by AML and Fabric."
  type = object({
    enabled             = bool
    resource_id         = string
    subresource_targets = optional(list(string), ["blob", "dfs"])
  })
  default = {
    enabled             = false
    resource_id         = ""
    subresource_targets = ["blob", "dfs"]
  }
}
