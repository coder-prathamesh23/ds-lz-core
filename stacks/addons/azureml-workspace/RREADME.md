# Stack: addons/azureml-workspace

This stack deploys the AML workspace after the base Data Science landing zone exists.

## Preferred deployment flow
1. deploy `stacks/data-science-lz-core`
2. confirm the required baseline dependency resources exist
3. deploy `stacks/addons/azureml-workspace`

## Remote state pattern
The add-on can read the base stack outputs from remote state so you do not need to manually copy:
- resource group name
- location
- tags
- VNet / subnet IDs
- Key Vault ID
- Storage Account ID
- Application Insights ID
- optional ACR ID and admin flag

## Private endpoint pattern
If you enable the AML workspace private endpoint:
- it is created in the private endpoints subnet from the base stack
- it attaches to existing central Private DNS zones via IDs passed in `workspace_private_dns_zone_ids`
- it does not create any Private DNS zones itself
