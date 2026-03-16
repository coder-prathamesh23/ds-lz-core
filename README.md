# Data Science Landing Zone Terraform Repo

This repo implements a **stacks + modules** deployment model for the **Data Science landing zone** and keeps **Azure Machine Learning (AML)** as a **separate add-on** that is deployed only after the base landing zone has been successfully applied.

## Repo structure

```text
modules/
  data-science-lz-core/
  addons/
    azureml-workspace/

stacks/
  data-science-lz-core/
  addons/
    azureml-workspace/
```

## Deployment model

### 1) Base landing zone
Deploy `stacks/data-science-lz-core` first.

The base stack is responsible for:
- Landing zone resource group (protected by default)
- Spoke VNet + required subnets **or** import of existing VNet/subnets
- vWAN / vHub connection to the hub using a provider alias for the hub subscription
- Optional shared baseline resources in the landing zone resource group:
  - Log Analytics Workspace
  - Application Insights
  - Storage Account
  - Container Registry
  - Key Vault

### 2) AML add-on
Deploy `stacks/addons/azureml-workspace` after the base stack.

The AML add-on can consume the base stack outputs through remote state, including:
- resource group name
- location
- tags
- spoke VNet ID
- workload subnet ID
- private endpoints subnet ID
- baseline dependency resource IDs (Key Vault, Storage, App Insights, optional ACR)

## Networking model

The base stack supports two modes:

- `network_mode = "create"`
  - creates the spoke VNet in the landing zone resource group
  - creates a workload subnet
  - creates a dedicated private endpoints subnet
  - sets `spoke_vnet_dns_servers` when Cloud Services provides central DNS resolver / forwarder IPs

- `network_mode = "import"`
  - references an existing spoke VNet
  - references an existing workload subnet
  - references an existing private endpoints subnet
  - creates no VNet or subnet resources

## Hub connectivity

The base stack creates an `azurerm_virtual_hub_connection` from the spoke VNet to the hub Virtual Hub.

Provider model:
- default `azurerm` provider is pinned to `spoke_subscription_id`
- aliased `azurerm.hub` provider is pinned to `hub_subscription_id`

By default, the connection keeps standard routing behavior and only sets:
- `internet_security_enabled`

No custom route table association / propagation settings are added unless Cloud Services explicitly asks later.

## Central DNS model

This repo does **not** create:
- Private DNS zones
- Private DNS zone virtual network links

That stays with Cloud Services.

Instead:
- the base stack can set custom VNet DNS servers for centralized private resolution
- add-ons can attach private endpoints to **existing** centrally managed Private DNS zones using zone IDs supplied by Cloud Services

## AML add-on notes

The AML add-on creates the workspace and can optionally create a workspace private endpoint in the dedicated private endpoints subnet.

It does **not** create Private DNS zones.
If workspace private endpointing is enabled, Cloud Services must provide the existing Private DNS zone IDs.

## CI/CD

`azure-pipelines.yml` implements:
- `terraform fmt -check` and `terraform validate`
- plan artifact publication
- approval-gated apply from the saved plan
- reuse of `.terraform.lock.hcl` during apply to reduce provider drift risk

The pipeline uses Azure DevOps Service Connections through `AzureCLI@2` and does not hardcode client-secret-only login assumptions.

## Important implementation choices

- Cross-variable checks for `create` vs `import` mode are implemented with `terraform_data` + `precondition` blocks so CI-friendly `terraform validate` behavior is preserved.
- The base module does **not** create networking. Networking stays in the base stack so the deployment model matches the Data Platform repo pattern.
- The AML add-on can work either from base remote state or from directly passed IDs if your team prefers not to read remote state.
