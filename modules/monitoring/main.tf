# ─────────────────────────────────────────────────────────────
# Monitoring Module - Main Configuration
# ─────────────────────────────────────────────────────────────

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# ─────────────────────────────────────────────────────────────
# Log Analytics Workspace
# ─────────────────────────────────────────────────────────────
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_workspace_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = var.tags

  depends_on = [data.azurerm_resource_group.rg]
}

# ─────────────────────────────────────────────────────────────
# Application Insights
# ─────────────────────────────────────────────────────────────
resource "azurerm_application_insights" "main" {
  name                = var.application_insights_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id

  retention_in_days = var.log_retention_days

  tags = var.tags

  depends_on = [azurerm_log_analytics_workspace.main]
}
