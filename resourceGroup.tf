# ═══════════════════════════════════════════════════════════════════════════════
# Resource Group
# ═══════════════════════════════════════════════════════════════════════════════
# Creates the main resource group that contains all DTE resources
# ═══════════════════════════════════════════════════════════════════════════════

module "resource_group" {
  source = "./modules/resource_group"

  resource_group_name = local.resource_group_name
  location            = var.azure_region
  tags                = local.common_tags
}
