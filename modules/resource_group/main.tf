# ═══════════════════════════════════════════════════════════════════════════════
# Resource Group Module
# ═══════════════════════════════════════════════════════════════════════════════
# Creates an Azure Resource Group - the container for all other resources
# ═══════════════════════════════════════════════════════════════════════════════

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

