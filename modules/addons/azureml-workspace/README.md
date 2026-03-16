# Module: azureml-workspace

This module creates an Azure Machine Learning workspace and can optionally create a workspace private endpoint.

## Important notes
- It does not create Private DNS zones.
- If `enable_workspace_private_endpoint = true`, provide the existing central Private DNS zone IDs from Cloud Services.
- The module accepts VNet and subnet IDs so the add-on remains aligned with the base landing zone networking contract, even if only the private endpoints subnet is used immediately.
