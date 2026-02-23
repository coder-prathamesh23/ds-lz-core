// Provider configuration removed to allow the root module (stack) to
// pass provider configurations and aliases (for example `azurerm` and
// `azurerm.hub`).  The provider requirement and aliases are declared
// in `versions.tf` via `configuration_aliases` so callers may provide
// aliased providers when needed.

// If you want to use this module standalone (without passing providers
// from the root), configure the provider in the root that calls this
// module. Avoid adding a `provider "azurerm" {}` block inside the
// module if you expect the caller to override or pass aliased
// provider configurations.
