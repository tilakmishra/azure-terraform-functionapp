# ═══════════════════════════════════════════════════════════════════════════════
# RBAC Role Assignments - Enterprise Grade Security
# ═══════════════════════════════════════════════════════════════════════════════
# Enables managed identity authentication for Function App to access Azure services
# without exposing credentials, following Microsoft security best practices.

# ───────────────────────────────────────────────────────────────────────────────
# Cosmos DB Access - Function App
# ───────────────────────────────────────────────────────────────────────────────
# Grant Function App managed identity the ability to read/write to Cosmos DB
# Role: "Cosmos DB Built-in Data Contributor" (00000000-0000-0000-0000-000000000002)
# Allows: CRUD operations on database documents via Azure SDK with DefaultAzureCredential
resource "azurerm_cosmosdb_sql_role_assignment" "function_app_cosmos_access" {
  resource_group_name = module.resource_group.name
  account_name        = module.cosmos_db.name
  role_definition_id  = "${module.cosmos_db.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = module.function_app.identity_principal_id
  scope               = module.cosmos_db.id
  depends_on          = [module.function_app, module.cosmos_db]
}

# ───────────────────────────────────────────────────────────────────────────────
# Key Vault Access - Function App
# ───────────────────────────────────────────────────────────────────────────────
# Grant Function App managed identity to read secrets from Key Vault
# Role: "Key Vault Secrets User" - read-only access to secret values
resource "azurerm_role_assignment" "function_app_keyvault_access" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.function_app.identity_principal_id

  depends_on = [module.function_app, module.key_vault]
}

# ───────────────────────────────────────────────────────────────────────────────
# Storage Account Access - Function App
# ───────────────────────────────────────────────────────────────────────────────
# Grant Function App managed identity to read from storage (for function code & files)
# Role: "Storage Blob Data Reader" - allows reading blob data required for function runtime
resource "azurerm_role_assignment" "function_app_storage_blob_read" {
  scope                = module.function_app.storage_account_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = module.function_app.identity_principal_id

  depends_on = [module.function_app]
}

# Grant Function App managed identity to write to storage logs/diagnostics
# Role: "Storage Queue Data Contributor" - allows writing to queue/monitoring data
resource "azurerm_role_assignment" "function_app_storage_queue_contributor" {
  scope                = module.function_app.storage_account_id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = module.function_app.identity_principal_id

  depends_on = [module.function_app]
}
