# Function App Configuration - Enterprise Secure

module "function_app" {
  source = "./modules/function_app"

  name                 = local.function_app_name
  location             = var.azure_region
  resource_group_name  = module.resource_group.name
  storage_account_name = local.storage_account_name
  tags                 = local.common_tags

  python_version = var.function_app_runtime_version

  app_settings = {
    "CosmosDbEndpoint"         = module.cosmos_db.endpoint
    "CosmosDbConnectionString" = module.cosmos_db.connection_string
    "CosmosDbDatabaseName"     = module.cosmos_db.database_name
    "CosmosDbContainerName"    = module.cosmos_db.container_name
    "KeyVaultUri"              = module.key_vault.uri
  }

  app_insights_connection_string = var.enable_monitoring ? module.app_insights[0].connection_string : ""

  # Network Security Configuration (Required)
  private_endpoint_subnet_id = module.virtualsubnet.subnets["private_endpoints"].id
  vnet_integration_subnet_id = module.virtualsubnet.subnets["function_app"].id

  depends_on = [
    module.resource_group,
    module.virtualsubnet,
    module.cosmos_db,
    module.key_vault,
    module.app_insights
  ]
}
