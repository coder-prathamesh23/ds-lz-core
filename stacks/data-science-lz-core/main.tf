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
  rg_name = var.allow_resource_group_destroy ? azurerm_resource_group.unprotected[0].name : azurerm_resource_group.protected[0].name
  rg_id   = var.allow_resource_group_destroy ? azurerm_resource_group.unprotected[0].id : azurerm_resource_group.protected[0].id

  import_spoke_vnet_name = try(var.spoke_vnet.name, "")
  import_spoke_vnet_rg   = try(var.spoke_vnet.resource_group_name, "")

  import_workload_subnet_vnet_name = try(var.workload_subnet.virtual_network_name, "") != "" ? try(var.workload_subnet.virtual_network_name, "") : local.import_spoke_vnet_name
  import_workload_subnet_rg_name   = try(var.workload_subnet.resource_group_name, "") != "" ? try(var.workload_subnet.resource_group_name, "") : local.import_spoke_vnet_rg

  import_private_endpoints_subnet_vnet_name = try(var.private_endpoints_subnet.virtual_network_name, "") != "" ? try(var.private_endpoints_subnet.virtual_network_name, "") : local.import_spoke_vnet_name
  import_private_endpoints_subnet_rg_name   = try(var.private_endpoints_subnet.resource_group_name, "") != "" ? try(var.private_endpoints_subnet.resource_group_name, "") : local.import_spoke_vnet_rg
}

resource "terraform_data" "input_checks" {
  input = {
    network_mode           = var.network_mode
    enable_vhub_connection = var.enable_vhub_connection
    resource_group_name    = var.resource_group_name
  }

  lifecycle {
    precondition {
      condition = var.network_mode == "create" ? (
        var.spoke_vnet_name != ""
        && length(var.spoke_vnet_address_space) > 0
        && var.workload_subnet_name != ""
        && length(var.workload_subnet_address_prefixes) > 0
        && var.private_endpoints_subnet_name != ""
        && length(var.private_endpoints_subnet_address_prefixes) > 0
      ) : true
      error_message = "network_mode=create requires spoke_vnet_name, spoke_vnet_address_space, workload_subnet_name, workload_subnet_address_prefixes, private_endpoints_subnet_name, and private_endpoints_subnet_address_prefixes."
    }

    precondition {
      condition = var.network_mode == "import" ? (
        try(var.spoke_vnet.id, "") != ""
        || (
          local.import_spoke_vnet_name != ""
          && local.import_spoke_vnet_rg != ""
        )
      ) : true
      error_message = "network_mode=import requires spoke_vnet.id or spoke_vnet.name + spoke_vnet.resource_group_name."
    }

    precondition {
      condition = var.network_mode == "import" ? (
        try(var.workload_subnet.id, "") != ""
        || (
          try(var.workload_subnet.name, "") != ""
          && local.import_workload_subnet_vnet_name != ""
          && local.import_workload_subnet_rg_name != ""
        )
      ) : true
      error_message = "network_mode=import requires workload_subnet.id or workload_subnet.name with resolvable virtual network and resource group."
    }

    precondition {
      condition = var.network_mode == "import" ? (
        try(var.private_endpoints_subnet.id, "") != ""
        || (
          try(var.private_endpoints_subnet.name, "") != ""
          && local.import_private_endpoints_subnet_vnet_name != ""
          && local.import_private_endpoints_subnet_rg_name != ""
        )
      ) : true
      error_message = "network_mode=import requires private_endpoints_subnet.id or private_endpoints_subnet.name with resolvable virtual network and resource group."
    }

    precondition {
      condition     = var.enable_vhub_connection ? var.hub_virtual_hub_id != "" : true
      error_message = "enable_vhub_connection=true but hub_virtual_hub_id is empty."
    }
  }
}

data "azurerm_virtual_network" "spoke" {
  count               = var.network_mode == "import" && try(var.spoke_vnet.id, "") == "" ? 1 : 0
  name                = local.import_spoke_vnet_name
  resource_group_name = local.import_spoke_vnet_rg
}

data "azurerm_subnet" "workload" {
  count                = var.network_mode == "import" && try(var.workload_subnet.id, "") == "" ? 1 : 0
  name                 = try(var.workload_subnet.name, "")
  virtual_network_name = local.import_workload_subnet_vnet_name
  resource_group_name  = local.import_workload_subnet_rg_name
}

data "azurerm_subnet" "private_endpoints" {
  count                = var.network_mode == "import" && try(var.private_endpoints_subnet.id, "") == "" ? 1 : 0
  name                 = try(var.private_endpoints_subnet.name, "")
  virtual_network_name = local.import_private_endpoints_subnet_vnet_name
  resource_group_name  = local.import_private_endpoints_subnet_rg_name
}

resource "azurerm_virtual_network" "spoke" {
  count               = var.network_mode == "create" ? 1 : 0
  name                = var.spoke_vnet_name
  location            = var.location
  resource_group_name = local.rg_name
  address_space       = var.spoke_vnet_address_space
  dns_servers         = var.spoke_vnet_dns_servers
  tags                = var.tags

  depends_on = [terraform_data.input_checks]
}

resource "azurerm_subnet" "workload" {
  count                = var.network_mode == "create" ? 1 : 0
  name                 = var.workload_subnet_name
  resource_group_name  = local.rg_name
  virtual_network_name = azurerm_virtual_network.spoke[0].name
  address_prefixes     = var.workload_subnet_address_prefixes

  # Workload subnet should keep PE policies enabled.
  # Private endpoints must be created only in the dedicated private endpoints subnet.
  private_endpoint_network_policies = "Enabled"
  depends_on                        = [terraform_data.input_checks]
}

resource "azurerm_subnet" "private_endpoints" {
  count                = var.network_mode == "create" ? 1 : 0
  name                 = var.private_endpoints_subnet_name
  resource_group_name  = local.rg_name
  virtual_network_name = azurerm_virtual_network.spoke[0].name
  address_prefixes     = var.private_endpoints_subnet_address_prefixes

  private_endpoint_network_policies = "Disabled"

  depends_on = [terraform_data.input_checks]
}

locals {
  spoke_vnet_id = coalesce(
    try(azurerm_virtual_network.spoke[0].id, null),
    try(var.spoke_vnet.id, null),
    try(data.azurerm_virtual_network.spoke[0].id, null)
  )

  workload_subnet_id = coalesce(
    try(azurerm_subnet.workload[0].id, null),
    try(var.workload_subnet.id, null),
    try(data.azurerm_subnet.workload[0].id, null)
  )

  private_endpoints_subnet_id = coalesce(
    try(azurerm_subnet.private_endpoints[0].id, null),
    try(var.private_endpoints_subnet.id, null),
    try(data.azurerm_subnet.private_endpoints[0].id, null)
  )
}

module "data_science_lz_core" {
  source = "../../modules/data-science-lz-core"

  providers = {
    azurerm = azurerm
  }

  location            = var.location
  resource_group_name = local.rg_name
  resource_group_id   = local.rg_id
  tags                = var.tags

  spoke_vnet_id               = local.spoke_vnet_id
  workload_subnet_id          = local.workload_subnet_id
  private_endpoints_subnet_id = local.private_endpoints_subnet_id

  key_vault            = var.key_vault
  log_analytics        = var.log_analytics
  application_insights = var.application_insights
  storage_account      = var.storage_account
  container_registry   = var.container_registry

  depends_on = [terraform_data.input_checks]
}

resource "azurerm_virtual_hub_connection" "spoke" {
  count = var.enable_vhub_connection ? 1 : 0

  name                      = var.vhub_connection_name
  virtual_hub_id            = var.hub_virtual_hub_id
  remote_virtual_network_id = local.spoke_vnet_id
  internet_security_enabled = var.internet_security_enabled

  provider = azurerm.hub

  lifecycle {
    precondition {
      condition     = var.hub_virtual_hub_id != ""
      error_message = "enable_vhub_connection=true but hub_virtual_hub_id is empty."
    }

    precondition {
      condition     = local.spoke_vnet_id != null && local.spoke_vnet_id != ""
      error_message = "Spoke VNet ID could not be resolved."
    }
  }

  depends_on = [terraform_data.input_checks]
}
