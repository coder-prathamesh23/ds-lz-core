# Stack: data-science-lz-core

Deploys the **minimal** Data Science Landing Zone baseline:
- Spoke VNet + subnets
- Hub connectivity (peering or vWAN hub connection)
- Links to central Private DNS zones (optional)
- Optional baseline shared resources (Core RG):
  - Key Vault
  - Log Analytics + App Insights
  - Storage Account
  - Container Registry

## Safe destroy behavior
By default, the Resource Group is protected (`prevent_destroy`).

To allow destroy (e.g., for a sandbox), set:
`allow_resource_group_destroy = true`
