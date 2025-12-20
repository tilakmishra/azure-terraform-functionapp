# Outputs

# Resource Group
output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "Resource group ID"
  value       = module.resource_group.id
}

# Networking
output "vnet_id" {
  description = "Virtual Network ID"
  value       = module.virtualnetwork.id
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = module.virtualnetwork.name
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = module.virtualsubnet.subnet_ids
}

# Function App
output "function_app_id" {
  description = "Function App ID"
  value       = module.function_app.id
}

output "function_app_name" {
  description = "Function App name"
  value       = module.function_app.name
}

output "function_app_hostname" {
  description = "Function App hostname"
  value       = module.function_app.default_hostname
}

# Static Web App
output "static_web_app_id" {
  description = "Static Web App ID"
  value       = module.static_web_app.id
}

output "static_web_app_name" {
  description = "Static Web App name"
  value       = module.static_web_app.name
}

output "static_web_app_hostname" {
  description = "Static Web App hostname"
  value       = module.static_web_app.default_host_name
}

# Cosmos DB
output "cosmos_db_id" {
  description = "Cosmos DB account ID"
  value       = module.cosmos_db.id
}

output "cosmos_db_endpoint" {
  description = "Cosmos DB endpoint"
  value       = module.cosmos_db.endpoint
}

# Key Vault
output "key_vault_id" {
  description = "Key Vault ID"
  value       = module.key_vault.id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = module.key_vault.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.key_vault.uri
}

# Monitoring
output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = try(module.log_analytics[0].id, null)
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = try(module.app_insights[0].connection_string, null)
  sensitive   = true
}
