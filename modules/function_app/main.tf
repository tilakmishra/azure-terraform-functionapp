# Function App Module - Enterprise Secure

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Storage Account for Function App
resource "azurerm_storage_account" "function_storage" {
  name                          = var.storage_account_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = true  # Required for Function App deployment
  tags                          = var.tags
}

# File Share for Function App content (required for VNet integration)
resource "azurerm_storage_share" "function_content" {
  name               = "${replace(var.name, "-", "")}content"
  storage_account_id = azurerm_storage_account.function_storage.id
  quota              = 50
}

# Private Endpoint for Storage Account (Blob)
resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pe-${var.storage_account_name}-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${var.storage_account_name}-blob"
    private_connection_resource_id = azurerm_storage_account.function_storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# Private Endpoint for Storage Account (File) - required for content share over VNet
resource "azurerm_private_endpoint" "storage_file" {
  name                = "pe-${var.storage_account_name}-file"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${var.storage_account_name}-file"
    private_connection_resource_id = azurerm_storage_account.function_storage.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# App Service Plan
resource "azurerm_service_plan" "function" {
  name                = "${var.name}-asp"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "EP1"
  tags                = var.tags
}

# Linux Function App with VNet Integration (Enterprise Secure)
resource "azurerm_linux_function_app" "main" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  service_plan_id               = azurerm_service_plan.function.id
  storage_account_name          = azurerm_storage_account.function_storage.name
  storage_account_access_key    = azurerm_storage_account.function_storage.primary_access_key
  https_only                    = true
  public_network_access_enabled = true  # Required for deployment and Static Web App access

  # VNet Integration for outbound traffic
  virtual_network_subnet_id = var.vnet_integration_subnet_id

  identity {
    type = "SystemAssigned"
  }

  app_settings = merge(var.app_settings, {
    "APPLICATIONINSIGHTS_CONNECTION_STRING"    = var.app_insights_connection_string
    "WEBSITE_VNET_ROUTE_ALL"                   = "1"
    "WEBSITE_CONTENTOVERVNET"                  = "1"
    "WEBSITE_CONTENTSHARE"                     = azurerm_storage_share.function_content.name
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = azurerm_storage_account.function_storage.primary_connection_string
  })

  site_config {
    application_stack {
      python_version = var.python_version
    }
    # Route all traffic through VNet
    vnet_route_all_enabled = true
  }

  tags = var.tags

  depends_on = [
    azurerm_storage_share.function_content,
    azurerm_private_endpoint.storage_blob,
    azurerm_private_endpoint.storage_file
  ]
}

# Private Endpoint for Function App (inbound)
resource "azurerm_private_endpoint" "function_app" {
  name                = "pe-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${var.name}"
    private_connection_resource_id = azurerm_linux_function_app.main.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  tags = var.tags
}
