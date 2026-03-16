output "id" {
  value       = azurerm_machine_learning_workspace.this.id
  description = "AML workspace ID."
}

output "name" {
  value       = azurerm_machine_learning_workspace.this.name
  description = "AML workspace name."
}

output "principal_id" {
  value       = azurerm_machine_learning_workspace.this.identity[0].principal_id
  description = "System-assigned managed identity principal ID."
}

output "spoke_vnet_id" {
  value       = var.spoke_vnet_id
  description = "Spoke VNet ID passed to the AML add-on."
}

output "workload_subnet_id" {
  value       = var.workload_subnet_id
  description = "Workload subnet ID passed to the AML add-on."
}

output "private_endpoints_subnet_id" {
  value       = var.private_endpoints_subnet_id
  description = "Private endpoints subnet ID passed to the AML add-on."
}

output "workspace_private_endpoint_id" {
  value       = try(azurerm_private_endpoint.workspace[0].id, null)
  description = "AML workspace private endpoint ID (if enabled)."
}

output "aml_storage_outbound_rule_ids" {
  value       = { for k, v in azapi_resource.aml_storage_outbound_rule : k => v.id }
  description = "AML managed outbound rule IDs for AML-owned storage."
}

output "aml_key_vault_outbound_rule_id" {
  value       = try(azapi_resource.aml_key_vault_outbound_rule[0].id, null)
  description = "AML managed outbound rule ID for Key Vault."
}

output "aml_acr_outbound_rule_ids" {
  value       = { for k, v in azapi_resource.aml_acr_outbound_rule : k => v.id }
  description = "AML managed outbound rule IDs for ACR."
}

output "shared_storage_outbound_rule_ids" {
  value       = { for k, v in azapi_resource.shared_storage_outbound_rule : k => v.id }
  description = "AML managed outbound rule IDs for the shared AML/Fabric storage account."
}
