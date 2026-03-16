output "resource_group_id" {
  value       = local.rg_id
  description = "Landing zone resource group ID."
}

output "resource_group_name" {
  value       = local.rg_name
  description = "Landing zone resource group name."
}

output "location" {
  value       = var.location
  description = "Landing zone region."
}

output "tags" {
  value       = var.tags
  description = "Common tags applied to the landing zone."
}

output "spoke_vnet_id" {
  value       = local.spoke_vnet_id
  description = "Spoke VNet ID."
}

output "workload_subnet_id" {
  value       = local.workload_subnet_id
  description = "Workload subnet ID."
}

output "private_endpoints_subnet_id" {
  value       = local.private_endpoints_subnet_id
  description = "Private endpoints subnet ID."
}

output "vhub_connection_id" {
  value       = try(azurerm_virtual_hub_connection.spoke[0].id, null)
  description = "Virtual Hub connection ID (if enabled)."
}

output "key_vault_id" {
  value       = module.data_science_lz_core.key_vault_id
  description = "Key Vault ID (if enabled)."
}

output "log_analytics_workspace_id" {
  value       = module.data_science_lz_core.log_analytics_workspace_id
  description = "Log Analytics workspace ID (if enabled)."
}

output "application_insights_id" {
  value       = module.data_science_lz_core.application_insights_id
  description = "Application Insights ID (if enabled)."
}

output "storage_account_id" {
  value       = module.data_science_lz_core.storage_account_id
  description = "Storage Account ID (if enabled)."
}

output "container_registry_id" {
  value       = module.data_science_lz_core.container_registry_id
  description = "Container Registry ID (if enabled)."
}

output "container_registry_admin_enabled" {
  value       = module.data_science_lz_core.container_registry_admin_enabled
  description = "Whether the Container Registry has admin enabled (if enabled)."
}
