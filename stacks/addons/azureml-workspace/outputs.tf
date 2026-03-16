output "resource_group_name" {
  value       = local.resolved_resource_group_name
  description = "AML workspace resource group name."
}

output "location" {
  value       = local.resolved_location
  description = "AML workspace location."
}

output "spoke_vnet_id" {
  value       = local.resolved_spoke_vnet_id
  description = "Resolved spoke VNet ID."
}

output "workload_subnet_id" {
  value       = local.resolved_workload_subnet_id
  description = "Resolved workload subnet ID."
}

output "private_endpoints_subnet_id" {
  value       = local.resolved_private_endpoints_subnet_id
  description = "Resolved private endpoints subnet ID."
}

output "azureml_workspace_id" {
  value       = module.azureml_workspace.id
  description = "AML workspace ID."
}

output "azureml_workspace_name" {
  value       = module.azureml_workspace.name
  description = "AML workspace name."
}

output "azureml_workspace_principal_id" {
  value       = module.azureml_workspace.principal_id
  description = "AML workspace managed identity principal ID."
}

output "azureml_workspace_private_endpoint_id" {
  value       = module.azureml_workspace.workspace_private_endpoint_id
  description = "AML workspace private endpoint ID (if enabled)."
}

output "aml_storage_outbound_rule_ids" {
  value       = module.azureml_workspace.aml_storage_outbound_rule_ids
  description = "Managed outbound rule IDs for AML-owned storage."
}

output "aml_key_vault_outbound_rule_id" {
  value       = module.azureml_workspace.aml_key_vault_outbound_rule_id
  description = "Managed outbound rule ID for Key Vault."
}

output "aml_acr_outbound_rule_ids" {
  value       = module.azureml_workspace.aml_acr_outbound_rule_ids
  description = "Managed outbound rule IDs for ACR."
}

output "shared_storage_outbound_rule_ids" {
  value       = module.azureml_workspace.shared_storage_outbound_rule_ids
  description = "Managed outbound rule IDs for the shared AML/Fabric storage account."
}
