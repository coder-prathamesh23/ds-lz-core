# Data Science Landing Zone Terraform Repo (Core + Add-ons)

This repo deploys a **minimal, enterprise-ready** baseline for a **Data Science subscription (spoke)**, designed to be layered with add-ons later.

## What you deploy first
- `stacks/data-science-lz-core` — baseline landing zone for the **Data Science subscription**:
  - Spoke VNet + subnets (workload + private endpoints)
  - Hub connectivity (**VNet peering** OR **vWAN virtual hub connection**)
  - Private DNS **VNet links** to hub-managed private DNS zones (optional scaffolding)
  - Baseline shared resources (optional, per standards):
    - Key Vault
    - Log Analytics + Application Insights
    - Storage Account (name exception: no hyphens)
    - Container Registry (name exception: no hyphens)

## Module layout
`modules/data-science-lz-core` is a single self-contained module (no nested component modules) to keep the baseline simple and reviewable.

## Add-ons (optional)
Anything beyond the baseline belongs under:
- `modules/addons/*` and `stacks/addons/*`

Example stub included:
- `azureml-workspace` (optional) – reserved spot for AML workspace + future private endpoint patterns.

## CI/CD
- Single pipeline: `azure-pipelines.yml`
  - Parameters: `action` (plan/apply/destroy) and `stackPath`

Backend: Azure Blob Storage (configured via pipeline variables).

## Naming standards
This repo aligns to: `resource-subname-env-projectname-location`

Exceptions enforced in code:
- **Storage account** names: lowercase alphanumeric only (no hyphens)
- **Container Registry (ACR)** names: alphanumeric only (no hyphens) and globally unique

See `stacks/data-science-lz-core/terraform.tfvars` for examples.
