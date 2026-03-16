spoke_subscription_id = "00000000-0000-0000-0000-000000000000"

# Leave location/resource_group_name/tags empty to resolve them from core remote state.
location            = ""
resource_group_name = ""
tags                = {}

ml_workspace_name             = "mlw-core-dev-dslz-westus3"
sku_name                      = "Basic"
public_network_access_enabled = false
high_business_impact          = false

managed_network = {
  isolation_mode                = "AllowOnlyApprovedOutbound"
  provision_on_creation_enabled = true
}

core_remote_state = {
  enabled              = true
  resource_group_name  = "rg-tfstate-prod-shared"
  storage_account_name = "sttfstateprodshared01"
  container_name       = "tfstate"
  key                  = "stacks/data-science-lz-core/terraform.tfstate"
  use_azuread_auth     = true
}

# Optional direct overrides if you do not want to read core remote state.
#application_insights_id          = ""
#key_vault_id                     = ""
#storage_account_id               = ""
#container_registry_id            = ""
#container_registry_admin_enabled = true
#spoke_vnet_id                    = ""
#workload_subnet_id               = ""
#private_endpoints_subnet_id      = ""

# AML workspace PE in the DSLZ spoke VNet.
enable_workspace_private_endpoint = true
workspace_private_endpoint_name   = "pe-mlw-core-dev-dslz-westus3"
workspace_private_dns_zone_ids = [
  # Cloud Services should provide the existing zone IDs, for example:
  # "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/privatelink.api.azureml.ms",
  # "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/privatelink.notebooks.azure.net"
]

# AML-owned dependencies through AML managed network.
aml_primary_outbound_rules = {
  enable_storage              = true
  storage_subresource_targets = ["blob"]
  enable_key_vault            = true
  enable_acr                  = true
  acr_subresource_targets     = ["registry"]
}

# Separate shared storage account between AML and Fabric.
# Turn this on once Cloud Services / Fabric gives you the shared storage resource ID.
shared_storage = {
  enabled             = false
  resource_id         = ""
  subresource_targets = ["blob", "dfs"]
}
