# ═══════════════════════════════════════════════════════════════════════════════
# Application Insights
# ═══════════════════════════════════════════════════════════════════════════════
# Creates Application Insights for application monitoring
# ═══════════════════════════════════════════════════════════════════════════════

module "app_insights" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/app_insights"

  name                       = "appi-${local.name_prefix}"
  location                   = var.azure_region
  resource_group_name        = module.resource_group.name
  log_analytics_workspace_id = module.log_analytics[0].id
  retention_in_days          = var.log_retention_days
  tags                       = local.common_tags

  depends_on = [module.log_analytics]
}
