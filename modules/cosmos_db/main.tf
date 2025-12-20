# Cosmos DB Module - Enterprise Secure

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Cosmos DB Account with VNet filtering (Enterprise Secure)
resource "azurerm_cosmosdb_account" "main" {
  name                              = var.name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  offer_type                        = "Standard"
  public_network_access_enabled     = false
  is_virtual_network_filter_enabled = true

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  # Allow access from specific subnets via service endpoints
  dynamic "virtual_network_rule" {
    for_each = var.allowed_subnet_ids
    content {
      id                                   = virtual_network_rule.value
      ignore_missing_vnet_service_endpoint = false
    }
  }

  tags = var.tags
}

# Cosmos DB SQL Database
resource "azurerm_cosmosdb_sql_database" "database" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = var.throughput
}

# Cosmos DB Container
resource "azurerm_cosmosdb_sql_container" "container" {
  name                = var.container_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.database.name
  partition_key_paths = [var.partition_key_path]

  indexing_policy {
    indexing_mode = "consistent"
    included_path {
      path = "/*"
    }
  }
}

# Private Endpoint for Cosmos DB
resource "azurerm_private_endpoint" "cosmos_db" {
  name                = "pe-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${var.name}"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "cosmos_db" {
  count = var.enable_diagnostics ? 1 : 0

  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_cosmosdb_account.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "DataPlaneRequests"
  }
}
