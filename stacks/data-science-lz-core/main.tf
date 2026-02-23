module "data_science_lz_core" {
  source = "../../modules/data-science-lz-core"

  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }

  location                     = var.location
  resource_group_name          = var.resource_group_name
  tags                         = var.tags
  allow_resource_group_destroy = var.allow_resource_group_destroy

  vnet    = var.vnet
  subnets = var.subnets

  hub_connectivity = var.hub_connectivity
  private_dns      = var.private_dns

  # Baseline shared resources (optional)
  log_analytics        = var.log_analytics
  application_insights = var.application_insights
  storage_account      = var.storage_account
  container_registry   = var.container_registry
  key_vault            = var.key_vault
}
