location                     = "westus3"
resource_group_name          = "rg-core-dev-dslz-westus3"
allow_resource_group_destroy = false

spoke_subscription_id = "00000000-0000-0000-0000-000000000000"
hub_subscription_id   = "00000000-0000-0000-0000-000000000000"

tags = {
  Owner              = "mlops-team"
  CostCenter         = "TBD"
  Environment        = "dev"
  Project            = "dslz"
  DataClassification = "internal"
  ManagedBy          = "terraform"
}

# ---------------------------
# Networking
# ---------------------------
network_mode = "create"

spoke_vnet_name          = "vnet-spoke-dev-dslz-westus3"
spoke_vnet_address_space = ["10.92.0.0/23"]
spoke_vnet_dns_servers   = []

workload_subnet_name                      = "snet-workload-dev-dslz-westus3"
workload_subnet_address_prefixes          = ["10.92.0.0/24"]
private_endpoints_subnet_name             = "snet-pe-dev-dslz-westus3"
private_endpoints_subnet_address_prefixes = ["10.92.1.0/26"]

# ---------------------------
# Hub connectivity
# ---------------------------
enable_vhub_connection    = true
hub_virtual_hub_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-prod-westus3/providers/Microsoft.Network/virtualHubs/vhub-prod-westus3"
vhub_connection_name      = "conn-dslz-dev-westus3"
internet_security_enabled = true

# ---------------------------
# AML baseline resources
# Log Analytics is the only piece intentionally left out for now.
# ---------------------------
log_analytics = {
  enabled = false
  name    = ""
}

application_insights = {
  enabled          = true
  name             = "appi-core-dev-dslz-westus3"
  application_type = "web"
}

storage_account = {
  enabled                         = true
  name                            = "stdslzdevwestus301"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = false
  shared_access_key_enabled       = true
  allow_nested_items_to_be_public = false
}

container_registry = {
  enabled                       = true
  name                          = "crdslzdevwestus301"
  sku                           = "Premium"
  admin_enabled                 = true
  public_network_access_enabled = false
}

key_vault = {
  enabled                       = true
  name                          = "kv-sec-dev-dslz-wus3"
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  public_network_access_enabled = false
}
