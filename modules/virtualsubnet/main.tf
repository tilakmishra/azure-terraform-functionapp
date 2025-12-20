# ─────────────────────────────────────────────────────────────
# Virtual Subnet Module - Main Configuration
# Creates Subnet resources within an existing Virtual Network
# ─────────────────────────────────────────────────────────────

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Data source: Get resource group reference
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Data source: Get Virtual Network reference
data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
}

# ─────────────────────────────────────────────────────────────
# Subnets (Dynamic creation based on subnet_configs)
# ─────────────────────────────────────────────────────────────
resource "azurerm_subnet" "subnets" {
  for_each = var.subnet_configs

  name                 = "subnet-${each.key}-${var.environment}"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints

  # Disable private endpoint network policies (required for private endpoints)
  private_endpoint_network_policies = "Disabled"

  # Enable delegation if specified (for App Service VNet integration)
  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }

  depends_on = [data.azurerm_virtual_network.vnet]
}
