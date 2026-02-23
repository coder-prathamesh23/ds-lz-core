output "resource_group_id" {
  value       = local.rg_id
  description = "Resource group ID for the landing zone."
}

output "vnet_id" {
  value       = azurerm_virtual_network.spoke.id
  description = "Spoke VNet ID."
}

output "subnet_ids" {
  value       = { for k, s in azurerm_subnet.this : k => s.id }
  description = "Map of subnet ids."
}

output "key_vault_id" {
  value       = try(azurerm_key_vault.this[0].id, null)
  description = "Key Vault ID (if enabled)."
}

output "log_analytics_workspace_id" {
  value       = try(azurerm_log_analytics_workspace.this[0].id, null)
  description = "Log Analytics Workspace ID (if enabled)."
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
