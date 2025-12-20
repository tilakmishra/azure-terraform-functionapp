# ═══════════════════════════════════════════════════════════════════════════════
# Application Insights Module
# ═══════════════════════════════════════════════════════════════════════════════
# Creates Application Insights for application monitoring and diagnostics
# ═══════════════════════════════════════════════════════════════════════════════

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_application_insights" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.log_analytics_workspace_id
  application_type    = "web"
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

