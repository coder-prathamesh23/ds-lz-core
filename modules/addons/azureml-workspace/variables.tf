variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) default = {} }

# Placeholder inputs for future AML work:
variable "ml_workspace_name" { type = string }
variable "application_insights_id" { type = string }
variable "key_vault_id" { type = string }
variable "storage_account_id" { type = string }
variable "container_registry_id" { type = string default = "" }
