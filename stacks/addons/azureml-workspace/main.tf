data "azurerm_client_config" "current" {}

locals {
  workspace_private_endpoint_name = var.workspace_private_endpoint_name != "" ? var.workspace_private_endpoint_name : "pe-${var.ml_workspace_name}"
  managed_network_parent_id       = "${azapi_resource.this.id}/managedNetworks/default"
  resource_group_id               = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"

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

resource "azapi_resource" "this" {
  type      = "Microsoft.MachineLearningServices/workspaces@2025-06-01"
  name      = var.ml_workspace_name
  parent_id = local.resource_group_id
  location  = var.location
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    sku = {
      name = var.sku_name
    }

    properties = {
      applicationInsights = var.application_insights_id
      keyVault            = var.key_vault_id
      storageAccount      = var.storage_account_id
      containerRegistry   = var.container_registry_id

      hbiWorkspace       = var.high_business_impact
      publicNetworkAccess = var.public_network_access_enabled ? "Enabled" : "Disabled"
      provisionNetworkNow = try(var.managed_network.provision_on_creation_enabled, true)

      managedNetwork = {
        isolationMode = try(var.managed_network.isolation_mode, "AllowOnlyApprovedOutbound")
      }
    }
  }

  schema_validation_enabled = false
  response_export_values    = ["identity.principalId"]

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
    private_connection_resource_id = azapi_resource.this.id
    is_manual_connection           = false
    subresource_names              = var.workspace_private_service_subresource_names
  }

  private_dns_zone_group {
    name                 = "aml-workspace-dns"
    private_dns_zone_ids = var.workspace_private_dns_zone_ids
  }

  depends_on = [azapi_resource.this]
}

resource "azapi_resource" "aml_storage_outbound_rule" {
  for_each = local.aml_storage_rule_targets

  type      = "Microsoft.MachineLearningServices/workspaces/managedNetworks/outboundRules@2025-10-01-preview"
  name      = each.value == "blob" ? "amlblob" : each.value == "dfs" ? "amldfs" : "amlstorage"
  parent_id = local.managed_network_parent_id

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

  schema_validation_enabled = false

  depends_on = [azapi_resource.this]
}

resource "azapi_resource" "aml_key_vault_outbound_rule" {
  count = try(var.aml_primary_outbound_rules.enable_key_vault, true) ? 1 : 0

  type      = "Microsoft.MachineLearningServices/workspaces/managedNetworks/outboundRules@2025-10-01-preview"
  name      = "amlvault"
  parent_id = local.managed_network_parent_id

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

  schema_validation_enabled = false

  depends_on = [azapi_resource.this]
}

resource "azapi_resource" "aml_acr_outbound_rule" {
  for_each = local.aml_acr_rule_targets

  type      = "Microsoft.MachineLearningServices/workspaces/managedNetworks/outboundRules@2025-10-01-preview"
  name      = each.value == "registry" ? "amlacr" : "amlacrdata"
  parent_id = local.managed_network_parent_id

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

  schema_validation_enabled = false

  depends_on = [azapi_resource.this]
}

resource "azapi_resource" "shared_storage_outbound_rule" {
  for_each = local.shared_storage_rule_targets

  type      = "Microsoft.MachineLearningServices/workspaces/managedNetworks/outboundRules@2025-10-01-preview"
  name      = each.value == "blob" ? "sharedblob" : each.value == "dfs" ? "shareddfs" : "sharedstorage"
  parent_id = local.managed_network_parent_id

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

  schema_validation_enabled = false

  depends_on = [azapi_resource.this]
}
