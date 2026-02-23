# -----------------------
# Stack identity / naming
# Naming standard: resource-subname-env-projectname-location
# -----------------------
location                     = "eastus2"
resource_group_name          = "rg-core-dev-dslz-eastus2"
allow_resource_group_destroy = false

tags = {
  Owner              = "mlops-team"
  CostCenter         = "TBD"
  Environment        = "dev"
  Project            = "dslz"
  DataClassification = "internal"
  ManagedBy          = "terraform"
}

# -----------------------
# Networking (minimal)
# -----------------------
vnet = {
  name          = "vnet-spoke-dev-dslz-eastus2"
  address_space = ["10.92.0.0/23"]
}

# One workload subnet + one private endpoint subnet (matches the design diagram)
subnets = {
  workload = {
    name             = "snet-workload-dev-dslz-eastus2"
    address_prefixes = ["10.92.0.0/24"]
  }

  private_endpoints = {
    name             = "snet-pe-dev-dslz-eastus2"
    address_prefixes = ["10.92.1.0/26"]

    # AzureRM expects string values: "Enabled" / "Disabled"
    private_endpoint_network_policies             = "Disabled"
    private_link_service_network_policies_enabled = "Enabled"
  }
}

# -----------------------
# Hub connectivity
# -----------------------
hub_subscription_id = "" # set if hub is in a different subscription

hub_connectivity = {
  enabled           = true
  connectivity_type = "vnet_peering" # or "vwan_virtual_hub"

  # If peering: prefer hub_vnet_id, otherwise provide hub_vnet_name + hub_resource_group_name
  hub_vnet_id             = ""
  hub_vnet_name           = ""
  hub_resource_group_name = ""
  manage_hub_side_peering = false

  # If vWAN:
  virtual_hub_id             = ""
  virtual_hub_route_table_id = ""
  propagated_route_table_ids = []
  labels                     = []
}

# -----------------------
# Private DNS (hub-managed zones) - optional scaffolding
# -----------------------
private_dns = {
  enabled                 = false
  hub_private_dns_rg_name = "rg-dns-prod-dslz-eastus2"
  zone_names = [
    # Add only the zones your hub team manages centrally (examples):
    # "privatelink.vaultcore.azure.net",
    # "privatelink.azurecr.io",
    # "privatelink.blob.core.windows.net"
  ]
}

# -----------------------
# Baseline shared resources (Core RG) - optional
# NOTE: KV name is globally unique; Storage + ACR names cannot have hyphens.
# -----------------------
log_analytics = {
  enabled           = false
  name              = "log-core-dev-dslz-eastus2"
  retention_in_days = 30
}

application_insights = {
  enabled          = false
  name             = "appi-core-dev-dslz-eastus2"
  application_type = "web"
}

storage_account = {
  enabled                         = false
  name                            = "stdatadevdslzeastus201" # <-- replace; must be lowercase alphanumeric only (no spaces/no hyphens)
  public_network_access_enabled   = false
  shared_access_key_enabled       = true
  allow_nested_items_to_be_public = false
}

container_registry = {
  enabled                       = false
  name                          = "crmlopsdevdslzeastus201" # <-- replace; must be alphanumeric only (no hyphens)
  sku                           = "Standard"
  admin_enabled                 = false
  public_network_access_enabled = true
}

key_vault = {
  enabled                       = false
  name                          = "kv-sec-dev-dslz-eastus2" # <-- replace if collision; must be globally unique
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  public_network_access_enabled = false
}
