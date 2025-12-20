# ═══════════════════════════════════════════════════════════════════════════════
# Private Endpoint Module
# ═══════════════════════════════════════════════════════════════════════════════
# Creates a Private Endpoint for secure connectivity to Azure services
# ═══════════════════════════════════════════════════════════════════════════════

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_private_endpoint" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.name}-connection"
    private_connection_resource_id = var.target_resource_id
    is_manual_connection           = false
    subresource_names              = var.subresource_names
  }

  tags = var.tags
}

