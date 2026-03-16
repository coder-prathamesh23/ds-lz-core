locals {
  workspace_private_endpoint_name = var.workspace_private_endpoint_name != "" ? var.workspace_private_endpoint_name : "pe-${var.ml_workspace_name}"
  managed_network_parent_id       = "${azurerm_machine_learning_workspace.this.id}/managedNetworks/default"

  aml_storage_rule_targets    = try(var.aml_primary_outbound_rules.enable_storage, true) ? toset(try(var.aml_primary_outbound_rules.storage_subresource_targets, ["blob"])) : toset([])
  aml_acr_rule_targets        = try(var.aml_primary_outbound_rules.enable_acr, true) ? toset(try(var.aml_primary_outbound_rules.acr_subresource_targets, ["registry"])) : toset([])
  shared_storage_rule_targets = var.shared_storage.enabled ? toset(var.shared_storage.subresource_targets) : toset([])
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
      condition     = var.application_insights_id != ""
      error_message = "application_insights_id must be provided."
    }

    precondition {
      condition     = var.key_vault_id != ""
      error_message = "key_vault_id must be provided."
    }

    precondition {
      condition     = var.storage_account_id != ""
      error_message = "storage_account_id must be provided."
    }

    precondition {
      condition     = var.container_registry_id != ""
      error_message = "container_registry_id must be provided."
    }

    precondition {
      condition     = var.container_registry_admin_enabled
      error_message = "The AML ACR must have admin access enabled for AML workspace association."
    }

    precondition {
      condition = (
        try(var.managed_network.isolation_mode, "AllowOnlyApprovedOutbound") != "Disabled"
        || (
          !try(var.aml_primary_outbound_rules.enable_storage, true)
          && !try(var.aml_primary_outbound_rules.enable_key_vault, true)
          && !try(var.aml_primary_outbound_rules.enable_acr, true)
          && !var.shared_storage.enabled
        )
      )
      error_message = "Managed outbound private endpoint rules require managed_network.isolation_mode to be enabled."
    }

    precondition {
      condition     = var.enable_workspace_private_endpoint ? var.private_endpoints_subnet_id != "" : true
      error_message = "enable_workspace_private_endpoint=true but private_endpoints_subnet_id is empty."
    }

    precondition {
      condition     = var.enable_workspace_private_endpoint ? length(var.workspace_private_dns_zone_ids) > 0 : true
      error_message = "enable_workspace_private_endpoint=true but workspace_private_dns_zone_ids is empty."
    }

    precondition {
      condition     = var.shared_storage.enabled ? var.shared_storage.resource_id != "" : true
      error_message = "shared_storage.enabled=true requires shared_storage.resource_id."
    }
  }
}

resource "azurerm_machine_learning_workspace" "this" {
  name                = var.ml_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name

  application_insights_id = var.application_insights_id
  key_vault_id            = var.key_vault_id
  storage_account_id      = var.storage_account_id
  container_registry_id   = var.container_registry_id

  sku_name                      = var.sku_name
  public_network_access_enabled = var.public_network_access_enabled
  high_business_impact          = var.high_business_impact

  managed_network {
    isolation_mode                = try(var.managed_network.isolation_mode, "AllowOnlyApprovedOutbound")
    provision_on_creation_enabled = try(var.managed_network.provision_on_creation_enabled, true)
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  timeouts {
    create = "90m"
    update = "90m"
    delete = "90m"
  }

  depends_on = [terraform_data.input_checks]
}

resource "azurerm_private_endpoint" "workspace" {
  count               = var.enable_workspace_private_endpoint ? 1 : 0
  name                = local.workspace_private_endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id

  private_service_connection {
    name                           = local.workspace_private_endpoint_name
    private_connection_resource_id = azurerm_machine_learning_workspace.this.id
    is_manual_connection           = false
    subresource_names              = var.workspace_private_service_subresource_names
  }

  private_dns_zone_group {
    name                 = "aml-workspace-dns"
    private_dns_zone_ids = var.workspace_private_dns_zone_ids
  }

  depends_on = [azurerm_machine_learning_workspace.this]
}

resource "azapi_resource" "aml_storage_outbound_rule" {
  for_each = local.aml_storage_rule_targets

  type      = "Microsoft.MachineLearningServices/workspaces/managedNetworks/outboundRules@2025-10-01-preview"
  name      = each.value == "blob" ? "amlblob" : each.value == "dfs" ? "amldfs" : "amlstorage"
  parent_id = local.managed_network_parent_id

  schema_validation_enabled = false

  body = {
    properties = {
      category = "UserDefined"
      type     = "PrivateEndpoint"
      destination = {
        serviceResourceId = var.storage_account_id
        subresourceTarget = each.value
      }
    }
  }

  depends_on = [azurerm_machine_learning_workspace.this]
}

resource "azapi_resource" "aml_key_vault_outbound_rule" {
  count = try(var.aml_primary_outbound_rules.enable_key_vault, true) ? 1 : 0

  type      = "Microsoft.MachineLearningServices/workspaces/managedNetworks/outboundRules@2025-10-01-preview"
  name      = "amlvault"
  parent_id = local.managed_network_parent_id

  schema_validation_enabled = false

  body = {
    properties = {
      category = "UserDefined"
      type     = "PrivateEndpoint"
      destination = {
        serviceResourceId = var.key_vault_id
        subresourceTarget = "vault"
      }
    }
  }

  depends_on = [azurerm_machine_learning_workspace.this]
}

resource "azapi_resource" "aml_acr_outbound_rule" {
  for_each = local.aml_acr_rule_targets

  type      = "Microsoft.MachineLearningServices/workspaces/managedNetworks/outboundRules@2025-10-01-preview"
  name      = each.value == "registry" ? "amlacr" : "amlacrdata"
  parent_id = local.managed_network_parent_id

  schema_validation_enabled = false

  body = {
    properties = {
      category = "UserDefined"
      type     = "PrivateEndpoint"
      destination = {
        serviceResourceId = var.container_registry_id
        subresourceTarget = each.value
      }
    }
  }

  depends_on = [azurerm_machine_learning_workspace.this]
}

resource "azapi_resource" "shared_storage_outbound_rule" {
  for_each = local.shared_storage_rule_targets

  type      = "Microsoft.MachineLearningServices/workspaces/managedNetworks/outboundRules@2025-10-01-preview"
  name      = each.value == "blob" ? "sharedblob" : each.value == "dfs" ? "shareddfs" : "sharedstorage"
  parent_id = local.managed_network_parent_id

  schema_validation_enabled = false

  body = {
    properties = {
      category = "UserDefined"
      type     = "PrivateEndpoint"
      destination = {
        serviceResourceId = var.shared_storage.resource_id
        subresourceTarget = each.value
      }
    }
  }

  depends_on = [azurerm_machine_learning_workspace.this]
}
