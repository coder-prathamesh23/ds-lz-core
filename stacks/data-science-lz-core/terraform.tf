terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

# Hub provider alias:
# - If hub is same subscription: omit hub_subscription_id and this will behave the same as default provider.
# - If hub is different subscription: set hub_subscription_id in tfvars.
provider "azurerm" {
  alias = "hub"
  features {}
  subscription_id = var.hub_subscription_id != "" ? var.hub_subscription_id : null
}
