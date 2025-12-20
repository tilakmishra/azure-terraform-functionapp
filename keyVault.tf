# Key Vault Configuration - Enterprise Secure

module "key_vault" {
  source = "./modules/key_vault"

  name                = local.key_vault_name
  location            = var.azure_region
  resource_group_name = module.resource_group.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.common_tags

  # Network Security Configuration (Required)
  private_endpoint_subnet_id = module.virtualsubnet.subnets["private_endpoints"].id
  allowed_subnet_ids = [
    module.virtualsubnet.subnets["function_app"].id,
    module.virtualsubnet.subnets["app_service"].id
  ]

  # Monitoring
  enable_diagnostics         = var.enable_monitoring
  log_analytics_workspace_id = var.enable_monitoring ? module.log_analytics[0].id : null

  depends_on = [module.resource_group, module.virtualsubnet, module.log_analytics]
}
