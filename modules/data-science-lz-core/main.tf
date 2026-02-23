data "azurerm_client_config" "current" {}

# ---------------------------
# Resource Group (protected by default)
# Terraform does not allow variables inside lifecycle.prevent_destroy.
# Use two mutually-exclusive RG resources and select via count.
# ---------------------------
resource "azurerm_resource_group" "protected" {
  count    = var.allow_resource_group_destroy ? 0 : 1
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "unprotected" {
  count    = var.allow_resource_group_destroy ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

locals {
  rg_name = var.resource_group_name
  rg_id   = var.allow_resource_group_destroy ? azurerm_resource_group.unprotected[0].id : azurerm_resource_group.protected[0].id
}

# ---------------------------
# Spoke VNet + Subnets
# ---------------------------
resource "azurerm_virtual_network" "spoke" {
  name                = var.vnet.name
  location            = var.location
  resource_group_name = local.rg_name
  address_space       = var.vnet.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each             = var.subnets
  name                 = each.value.name
  resource_group_name  = local.rg_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = try(each.value.service_endpoints, [])

  private_endpoint_network_policies                 = try(each.value.private_endpoint_network_policies, "Disabled")
  private_link_service_network_policies_enabled     = try(each.value.private_link_service_network_policies_enabled, "Enabled")

  dynamic "delegation" {
    for_each = try(each.value.delegations, [])
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# ---------------------------
# Hub Connectivity
# ---------------------------
# Peering: resolve hub VNet ID from explicit id OR name+RG lookup.
data "azurerm_virtual_network" "hub" {
  count               = var.hub_connectivity.enabled && var.hub_connectivity.connectivity_type == "vnet_peering" && try(var.hub_connectivity.hub_vnet_id, "") == "" ? 1 : 0
  name                = try(var.hub_connectivity.hub_vnet_name, "")
  resource_group_name = try(var.hub_connectivity.hub_resource_group_name, "")
  provider            = azurerm.hub
}

locals {
  resolved_hub_vnet_id = coalesce(
    try(var.hub_connectivity.hub_vnet_id, ""),
    try(data.azurerm_virtual_network.hub[0].id, null)
  )
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count                     = var.hub_connectivity.enabled && var.hub_connectivity.connectivity_type == "vnet_peering" ? 1 : 0
  name                      = "peer-${var.vnet.name}-to-hub"
  resource_group_name       = local.rg_name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = local.resolved_hub_vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false

  lifecycle {
    precondition {
      condition     = local.resolved_hub_vnet_id != null && local.resolved_hub_vnet_id != ""
      error_message = "Hub VNet ID could not be resolved. Provide hub_connectivity.hub_vnet_id OR hub_vnet_name + hub_resource_group_name."
    }
  }
}

# Optional: manage hub->spoke peering (requires hub vnet name + RG).
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  count                     = var.hub_connectivity.enabled && var.hub_connectivity.connectivity_type == "vnet_peering" && try(var.hub_connectivity.manage_hub_side_peering, false) ? 1 : 0
  name                      = "peer-hub-to-${var.vnet.name}"
  resource_group_name       = try(var.hub_connectivity.hub_resource_group_name, "")
  virtual_network_name      = try(var.hub_connectivity.hub_vnet_name, "")
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  provider                  = azurerm.hub

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false

  lifecycle {
    precondition {
      condition     = try(var.hub_connectivity.hub_vnet_name, "") != "" && try(var.hub_connectivity.hub_resource_group_name, "") != ""
      error_message = "hub_to_spoke peering requires hub_connectivity.hub_vnet_name and hub_connectivity.hub_resource_group_name."
    }
  }
}

# vWAN Virtual Hub connection (optional)
resource "azurerm_virtual_hub_connection" "spoke_to_vhub" {
  count                     = var.hub_connectivity.enabled && var.hub_connectivity.connectivity_type == "vwan_virtual_hub" ? 1 : 0
  name                      = "conn-${var.vnet.name}-to-vhub"
  virtual_hub_id            = try(var.hub_connectivity.virtual_hub_id, "")
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  provider                  = azurerm.hub

  lifecycle {
    precondition {
      condition     = try(var.hub_connectivity.virtual_hub_id, "") != ""
      error_message = "vWAN connectivity requires hub_connectivity.virtual_hub_id."
    }
  }

  dynamic "routing" {
    for_each = try(var.hub_connectivity.virtual_hub_route_table_id, "") != "" ? [1] : []
    content {
      associated_route_table_id = var.hub_connectivity.virtual_hub_route_table_id
      propagated_route_table {
        route_table_ids = try(var.hub_connectivity.propagated_route_table_ids, [])
        labels          = try(var.hub_connectivity.labels, [])
      }
    }
  }
}

# ---------------------------
# Private DNS: link spoke VNet to hub-managed zones
# ---------------------------
data "azurerm_private_dns_zone" "hub_zones" {
  for_each            = var.private_dns.enabled ? toset(try(var.private_dns.zone_names, [])) : toset([])
  name                = each.value
  resource_group_name = try(var.private_dns.hub_private_dns_rg_name, "")
  provider            = azurerm.hub
}

resource "azurerm_private_dns_zone_virtual_network_link" "links" {
  for_each              = var.private_dns.enabled ? data.azurerm_private_dns_zone.hub_zones : {}
  name                  = "lnk-${var.vnet.name}-${replace(each.key, ".", "-")}"
  resource_group_name   = try(var.private_dns.hub_private_dns_rg_name, "")
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
  provider              = azurerm.hub

  registration_enabled = false
  tags                 = var.tags
}

# ---------------------------
# Optional baseline shared resources (Core RG)
# ---------------------------

resource "azurerm_log_analytics_workspace" "this" {
  count               = var.log_analytics.enabled ? 1 : 0
  name                = var.log_analytics.name
  location            = var.location
  resource_group_name = local.rg_name
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
  resource_group_name = local.rg_name
  application_type    = try(var.application_insights.application_type, "web")

  # Workspace-based App Insights is preferred. If log analytics is disabled, this will be null.
  workspace_id = try(azurerm_log_analytics_workspace.this[0].id, null)

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
  resource_group_name      = local.rg_name
  account_tier             = try(var.storage_account.account_tier, "Standard")
  account_replication_type = try(var.storage_account.account_replication_type, "LRS")
  min_tls_version          = try(var.storage_account.min_tls_version, "TLS1_2")

  public_network_access_enabled       = try(var.storage_account.public_network_access_enabled, false)
  allow_nested_items_to_be_public     = try(var.storage_account.allow_nested_items_to_be_public, false)
  shared_access_key_enabled           = try(var.storage_account.shared_access_key_enabled, true)

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
  resource_group_name = local.rg_name
  sku                 = try(var.container_registry.sku, "Standard")
  admin_enabled       = try(var.container_registry.admin_enabled, false)

  public_network_access_enabled = try(var.container_registry.public_network_access_enabled, true)

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.container_registry.enabled == false || (var.container_registry.enabled == true && var.container_registry.name != "")
      error_message = "When container_registry.enabled is true, container_registry.name must be set."
    }
  }
}

# ---------------------------
# Optional Key Vault baseline
# ---------------------------
resource "azurerm_key_vault" "this" {
  count               = var.key_vault.enabled ? 1 : 0
  name                = var.key_vault.name
  location            = var.location
  resource_group_name = local.rg_name
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
