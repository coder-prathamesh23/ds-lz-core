data "azurerm_client_config" "current" {}

resource "azurerm_log_analytics_workspace" "this" {
  count               = var.log_analytics.enabled ? 1 : 0
  name                = var.log_analytics.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = try(var.log_analytics.sku, "PerGB2018")
  retention_in_days   = try(var.log_analytics.retention_in_days, 30)

  internet_ingestion_enabled = try(var.log_analytics.internet_ingestion_enabled, true)
  internet_query_enabled     = try(var.log_analytics.internet_query_enabled, true)

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.log_analytics.enabled == false || (var.log_analytics.enabled == true && var.log_analytics.name != "")
      error_message = "When log_analytics.enabled is true, log_analytics.name must be set."
    }
  }
}

resource "azurerm_application_insights" "this" {
  count               = var.application_insights.enabled ? 1 : 0
  name                = var.application_insights.name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = try(var.application_insights.application_type, "web")
  workspace_id        = try(azurerm_log_analytics_workspace.this[0].id, null)

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.application_insights.enabled == false || (var.application_insights.enabled == true && var.application_insights.name != "")
      error_message = "When application_insights.enabled is true, application_insights.name must be set."
    }
  }
}

resource "azurerm_storage_account" "this" {
  count                    = var.storage_account.enabled ? 1 : 0
  name                     = var.storage_account.name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = try(var.storage_account.account_tier, "Standard")
  account_replication_type = try(var.storage_account.account_replication_type, "LRS")
  min_tls_version          = try(var.storage_account.min_tls_version, "TLS1_2")

  public_network_access_enabled   = try(var.storage_account.public_network_access_enabled, false)
  allow_nested_items_to_be_public = try(var.storage_account.allow_nested_items_to_be_public, false)
  shared_access_key_enabled       = try(var.storage_account.shared_access_key_enabled, true)

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.storage_account.enabled == false || (var.storage_account.enabled == true && var.storage_account.name != "")
      error_message = "When storage_account.enabled is true, storage_account.name must be set."
    }
  }
}

resource "azurerm_container_registry" "this" {
  count               = var.container_registry.enabled ? 1 : 0
  name                = var.container_registry.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = try(var.container_registry.sku, "Premium")
  admin_enabled       = try(var.container_registry.admin_enabled, true)

  public_network_access_enabled = try(var.container_registry.public_network_access_enabled, false)

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.container_registry.enabled == false || (var.container_registry.enabled == true && var.container_registry.name != "")
      error_message = "When container_registry.enabled is true, container_registry.name must be set."
    }
  }
}

resource "azurerm_key_vault" "this" {
  count               = var.key_vault.enabled ? 1 : 0
  name                = var.key_vault.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = try(var.key_vault.sku_name, "standard")

  purge_protection_enabled      = try(var.key_vault.purge_protection_enabled, true)
  soft_delete_retention_days    = try(var.key_vault.soft_delete_retention_days, 7)
  public_network_access_enabled = try(var.key_vault.public_network_access_enabled, false)

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.key_vault.enabled == false || (var.key_vault.enabled == true && var.key_vault.name != "")
      error_message = "When key_vault.enabled is true, key_vault.name must be set."
    }
  }
}
