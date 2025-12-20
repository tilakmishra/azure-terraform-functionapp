# Static Web App Module

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_static_web_app" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_size            = "Free"
  sku_tier            = "Free"
  tags                = var.tags
}
