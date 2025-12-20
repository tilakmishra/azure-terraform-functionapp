# ═══════════════════════════════════════════════════════════════════════════════
# Log Analytics
# ═══════════════════════════════════════════════════════════════════════════════
# Creates Log Analytics Workspace for centralized logging
# ═══════════════════════════════════════════════════════════════════════════════

module "log_analytics" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/log_analytics"

  name                = "log-${local.name_prefix}"
  location            = var.azure_region
  resource_group_name = module.resource_group.name
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags

  depends_on = [module.resource_group]
}
