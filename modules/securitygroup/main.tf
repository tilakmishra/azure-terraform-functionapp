# ─────────────────────────────────────────────────────────────
# Security Group Module - Main Configuration
# Creates Network Security Groups and rules, associates with subnets
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

# ─────────────────────────────────────────────────────────────
# Network Security Groups (NSGs) - One per subnet
# ─────────────────────────────────────────────────────────────
resource "azurerm_network_security_group" "nsgs" {
  for_each = var.subnet_configs

  name                = "nsg-${each.key}-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────
# NSG Rules: Function App Subnet (ALLOW inbound HTTPS)
# ─────────────────────────────────────────────────────────────
resource "azurerm_network_security_rule" "function_app_inbound" {
  count = contains(keys(var.subnet_configs), "function_app") ? 1 : 0

  name                        = "allow-https-inbound-from-swa"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "AppService"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsgs["function_app"].name
}

resource "azurerm_network_security_rule" "function_app_outbound_to_privateendpoints" {
  count = contains(keys(var.subnet_configs), "function_app") ? 1 : 0

  name                        = "allow-outbound-to-vnet"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsgs["function_app"].name
}

# ─────────────────────────────────────────────────────────────
# NSG Rules: Private Endpoints Subnet
# ─────────────────────────────────────────────────────────────
resource "azurerm_network_security_rule" "private_endpoints_inbound" {
  count = contains(keys(var.subnet_configs), "private_endpoints") ? 1 : 0

  name                        = "allow-vnet-inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsgs["private_endpoints"].name
}

# ─────────────────────────────────────────────────────────────
# NSG Rules: App Service Subnet
# ─────────────────────────────────────────────────────────────
resource "azurerm_network_security_rule" "app_service_inbound" {
  count = contains(keys(var.subnet_configs), "app_service") ? 1 : 0

  name                        = "allow-https-inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsgs["app_service"].name
}

resource "azurerm_network_security_rule" "app_service_outbound" {
  count = contains(keys(var.subnet_configs), "app_service") ? 1 : 0

  name                        = "allow-outbound-to-vnet"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsgs["app_service"].name
}

# ─────────────────────────────────────────────────────────────
# Deny all by default (Explicit allow only)
# ─────────────────────────────────────────────────────────────
resource "azurerm_network_security_rule" "function_app_deny_outbound" {
  count = contains(keys(var.subnet_configs), "function_app") ? 1 : 0

  name                        = "deny-all-outbound"
  priority                    = 1000
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsgs["function_app"].name
}

resource "azurerm_network_security_rule" "function_app_deny_inbound" {
  count = contains(keys(var.subnet_configs), "function_app") ? 1 : 0

  name                        = "deny-all-inbound"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsgs["function_app"].name
}

resource "azurerm_network_security_rule" "private_endpoints_deny_inbound" {
  count = contains(keys(var.subnet_configs), "private_endpoints") ? 1 : 0

  name                        = "deny-all-inbound"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsgs["private_endpoints"].name
}

# ─────────────────────────────────────────────────────────────
# Associate NSGs with Subnets
# ─────────────────────────────────────────────────────────────
resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = var.subnet_ids

  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.nsgs[each.key].id

  depends_on = [
    azurerm_network_security_group.nsgs
  ]
}
