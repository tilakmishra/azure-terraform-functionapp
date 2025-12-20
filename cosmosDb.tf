# Cosmos DB Configuration - Enterprise Secure

module "cosmos_db" {
  source = "./modules/cosmos_db"

  name                = local.cosmos_db_name
  location            = var.azure_region
  resource_group_name = module.resource_group.name
  tags                = local.common_tags

  database_name      = "employeedb"
  container_name     = "employees"
  partition_key_path = "/departmentId"
  throughput         = var.cosmos_db_throughput

  # Network Security Configuration (Required)
  private_endpoint_subnet_id = module.virtualsubnet.subnets["private_endpoints"].id
  allowed_subnet_ids = [
    module.virtualsubnet.subnets["function_app"].id,
    module.virtualsubnet.subnets["data"].id
  ]

  # Monitoring
  enable_diagnostics         = var.enable_monitoring
  log_analytics_workspace_id = var.enable_monitoring ? module.log_analytics[0].id : null

  depends_on = [module.resource_group, module.virtualsubnet, module.log_analytics]
}
