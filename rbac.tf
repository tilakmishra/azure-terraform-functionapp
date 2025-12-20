# RBAC Role Assignments
# Note: Commenting out Cosmos DB RBAC - using connection string instead for simplicity

# # Grant Function App access to Cosmos DB using Azure RBAC
# resource "azurerm_cosmosdb_sql_role_assignment" "function_app_cosmos_access" {
#   resource_group_name = module.resource_group.name
#   account_name        = module.cosmos_db.name
#   role_definition_id  = "${module.cosmos_db.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
#   principal_id        = module.function_app.identity_principal_id
#   scope               = module.cosmos_db.id
#   depends_on = [module.function_app, module.cosmos_db]
# }

# Grant Function App access to Key Vault Secrets
resource "azurerm_role_assignment" "function_app_keyvault_access" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.function_app.identity_principal_id

  depends_on = [module.function_app, module.key_vault]
}
