# Static Web App Configuration

module "static_web_app" {
  source = "./modules/static_web_app"

  name                = local.static_web_app_name
  location            = var.azure_region
  resource_group_name = module.resource_group.name
  tags                = local.common_tags

  depends_on = [module.resource_group]
}
