terraform {
  required_version = ">= 1.7.0"

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
  subscription_id = var.spoke_subscription_id
}

provider "azurerm" {
  alias = "hub"
  features {}
  subscription_id = var.hub_subscription_id

  # Cloud Services owns resource provider registration in the hub subscription.
  resource_provider_registrations = "none"
}
