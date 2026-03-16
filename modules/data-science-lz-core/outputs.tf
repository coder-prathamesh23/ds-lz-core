output "resource_group_id" {
  value       = var.resource_group_id
  description = "Landing zone resource group ID."
}

output "resource_group_name" {
  value       = var.resource_group_name
  description = "Landing zone resource group name."
}

output "spoke_vnet_id" {
  value       = var.spoke_vnet_id
  description = "Spoke VNet ID."
}

output "workload_subnet_id" {
  value       = var.workload_subnet_id
  description = "Workload subnet ID."
}

output "private_endpoints_subnet_id" {
  value       = var.private_endpoints_subnet_id
  description = "Private endpoints subnet ID."
}

output "key_vault_id" {
  value       = try(azurerm_key_vault.this[0].id, null)
  description = "Key Vault ID (if enabled)."
}

output "log_analytics_workspace_id" {
  value       = try(azurerm_log_analytics_workspace.this[0].id, null)
  description = "Log Analytics workspace ID (if enabled)."
}

output "application_insights_id" {
  value       = try(azurerm_application_insights.this[0].id, null)
  description = "Application Insights ID (if enabled)."
}

output "storage_account_id" {
  value       = try(azurerm_storage_account.this[0].id, null)
  description = "Storage Account ID (if enabled)."
}

output "container_registry_id" {
  value       = try(azurerm_container_registry.this[0].id, null)
  description = "Container Registry ID (if enabled)."
}

output "container_registry_admin_enabled" {
  value       = try(azurerm_container_registry.this[0].admin_enabled, null)
  description = "Whether the Container Registry has admin access enabled (if enabled)."
}
