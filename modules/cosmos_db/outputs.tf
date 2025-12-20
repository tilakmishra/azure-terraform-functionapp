# Cosmos DB Module - Outputs

output "id" {
  description = "Cosmos DB account ID"
  value       = azurerm_cosmosdb_account.main.id
}

output "name" {
  description = "Cosmos DB account name"
  value       = azurerm_cosmosdb_account.main.name
}

output "endpoint" {
  description = "Cosmos DB endpoint"
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "connection_string" {
  description = "Cosmos DB connection string"
  value       = azurerm_cosmosdb_account.main.primary_sql_connection_string
  sensitive   = true
}

output "database_name" {
  description = "Database name"
  value       = azurerm_cosmosdb_sql_database.database.name
}

output "container_name" {
  description = "Container name"
  value       = azurerm_cosmosdb_sql_container.container.name
}
