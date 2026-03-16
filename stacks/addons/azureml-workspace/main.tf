data "terraform_remote_state" "core" {
  count   = var.core_remote_state.enabled ? 1 : 0
  backend = "azurerm"

  config = {
    resource_group_name  = var.core_remote_state.resource_group_name
    storage_account_name = var.core_remote_state.storage_account_name
    container_name       = var.core_remote_state.container_name
    key                  = var.core_remote_state.key
    use_azuread_auth     = try(var.core_remote_state.use_azuread_auth, true)
  }
}

locals {
  core_outputs = var.core_remote_state.enabled ? data.terraform_remote_state.core[0].outputs : {}

  resolved_location            = var.location != "" ? var.location : try(local.core_outputs.location, "")
  resolved_resource_group_name = var.resource_group_name != "" ? var.resource_group_name : try(local.core_outputs.resource_group_name, "")
  resolved_tags                = length(var.tags) > 0 ? var.tags : try(local.core_outputs.tags, {})

  resolved_application_insights_id = var.application_insights_id != "" ? var.application_insights_id : try(local.core_outputs.application_insights_id, "")
  resolved_key_vault_id            = var.key_vault_id != "" ? var.key_vault_id : try(local.core_outputs.key_vault_id, "")
  resolved_storage_account_id      = var.storage_account_id != "" ? var.storage_account_id : try(local.core_outputs.storage_account_id, "")
  resolved_container_registry_id   = var.container_registry_id != "" ? var.container_registry_id : try(local.core_outputs.container_registry_id, "")

  resolved_container_registry_admin_enabled = var.container_registry_id != "" ? var.container_registry_admin_enabled : try(local.core_outputs.container_registry_admin_enabled, false)

  resolved_spoke_vnet_id               = var.spoke_vnet_id != "" ? var.spoke_vnet_id : try(local.core_outputs.spoke_vnet_id, "")
  resolved_workload_subnet_id          = var.workload_subnet_id != "" ? var.workload_subnet_id : try(local.core_outputs.workload_subnet_id, "")
  resolved_private_endpoints_subnet_id = var.private_endpoints_subnet_id != "" ? var.private_endpoints_subnet_id : try(local.core_outputs.private_endpoints_subnet_id, "")
}

resource "terraform_data" "input_checks" {
  input = {
    ml_workspace_name = var.ml_workspace_name
  }

  lifecycle {
    precondition {
      condition     = var.ml_workspace_name != ""
      error_message = "ml_workspace_name must be set."
    }

    precondition {
      condition     = local.resolved_location != ""
      error_message = "location could not be resolved. Provide location directly or enable core_remote_state with a valid output."
    }

    precondition {
      condition     = local.resolved_resource_group_name != ""
      error_message = "resource_group_name could not be resolved. Provide resource_group_name directly or enable core_remote_state with a valid output."
    }

    precondition {
      condition     = local.resolved_application_insights_id != ""
      error_message = "application_insights_id could not be resolved. Enable the core baseline resource or pass the ID directly."
    }

    precondition {
      condition     = local.resolved_key_vault_id != ""
      error_message = "key_vault_id could not be resolved. Enable the core baseline resource or pass the ID directly."
    }

    precondition {
      condition     = local.resolved_storage_account_id != ""
      error_message = "storage_account_id could not be resolved. Enable the core baseline resource or pass the ID directly."
    }

    precondition {
      condition     = local.resolved_container_registry_id != ""
      error_message = "container_registry_id could not be resolved. Enable the core baseline resource or pass the ID directly."
    }

    precondition {
      condition     = var.enable_workspace_private_endpoint ? local.resolved_private_endpoints_subnet_id != "" : true
      error_message = "enable_workspace_private_endpoint=true but private_endpoints_subnet_id could not be resolved."
    }

    precondition {
      condition     = var.enable_workspace_private_endpoint ? length(var.workspace_private_dns_zone_ids) > 0 : true
      error_message = "enable_workspace_private_endpoint=true but workspace_private_dns_zone_ids is empty."
    }

    precondition {
      condition = var.core_remote_state.enabled ? (
        var.core_remote_state.resource_group_name != ""
        && var.core_remote_state.storage_account_name != ""
        && var.core_remote_state.container_name != ""
        && var.core_remote_state.key != ""
      ) : true
      error_message = "core_remote_state.enabled=true requires resource_group_name, storage_account_name, container_name, and key."
    }
  }
}

module "azureml_workspace" {
  source = "../../../modules/addons/azureml-workspace"

  location            = local.resolved_location
  resource_group_name = local.resolved_resource_group_name
  tags                = local.resolved_tags

  ml_workspace_name             = var.ml_workspace_name
  sku_name                      = var.sku_name
  public_network_access_enabled = var.public_network_access_enabled
  high_business_impact          = var.high_business_impact

  managed_network = var.managed_network

  application_insights_id          = local.resolved_application_insights_id
  key_vault_id                     = local.resolved_key_vault_id
  storage_account_id               = local.resolved_storage_account_id
  container_registry_id            = local.resolved_container_registry_id
  container_registry_admin_enabled = local.resolved_container_registry_admin_enabled

  spoke_vnet_id               = local.resolved_spoke_vnet_id
  workload_subnet_id          = local.resolved_workload_subnet_id
  private_endpoints_subnet_id = local.resolved_private_endpoints_subnet_id

  enable_workspace_private_endpoint = var.enable_workspace_private_endpoint
  workspace_private_endpoint_name   = var.workspace_private_endpoint_name
  workspace_private_dns_zone_ids    = var.workspace_private_dns_zone_ids

  aml_primary_outbound_rules = var.aml_primary_outbound_rules
  shared_storage             = var.shared_storage

  depends_on = [terraform_data.input_checks]
}
