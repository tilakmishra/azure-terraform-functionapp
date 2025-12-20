# ═══════════════════════════════════════════════════════════════════════════════
# Log Analytics Module
# ═══════════════════════════════════════════════════════════════════════════════
# Creates a Log Analytics Workspace for centralized logging
# ═══════════════════════════════════════════════════════════════════════════════

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

