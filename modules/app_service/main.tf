# ─────────────────────────────────────────────────────────────
# Azure App Service Module - Main Configuration
# Creates App Service Plan, Linux/Windows Web Apps, Private Endpoints,
# and Storage Mounts for production-ready deployments
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
# App Service Plan
# ─────────────────────────────────────────────────────────────
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.project_name}-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  os_type             = var.os_type
  sku_name            = var.sku_name

  # Zone redundancy for production workloads
  zone_balancing_enabled = var.zone_redundant

  # Worker count for scaling
  worker_count = var.worker_count

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────
# Linux Web Apps
# ─────────────────────────────────────────────────────────────
resource "azurerm_linux_web_app" "main" {
  for_each = var.os_type == "Linux" ? var.app_configs : {}

  name                = "app-${var.project_name}-${each.key}-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.main.id

  # HTTPS enforcement
  https_only = true

  # Client certificate mode
  client_certificate_enabled = lookup(each.value, "client_certificate_enabled", false)
  client_certificate_mode    = lookup(each.value, "client_certificate_mode", "Optional")

  # Virtual Network Integration
  virtual_network_subnet_id = var.vnet_integration_subnet_id

  # Managed Identity
  identity {
    type         = var.identity_type
    identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.user_assigned_identity_ids : null
  }

  site_config {
    # Always On for production
    always_on = lookup(each.value, "always_on", true)

    # HTTP/2 support
    http2_enabled = lookup(each.value, "http2_enabled", true)

    # Minimum TLS version
    minimum_tls_version = lookup(each.value, "minimum_tls_version", "1.2")

    # FTP state
    ftps_state = lookup(each.value, "ftps_state", "Disabled")

    # Health check
    health_check_path                 = lookup(each.value, "health_check_path", null)
    health_check_eviction_time_in_min = lookup(each.value, "health_check_eviction_time_in_min", 10)

    # VNet route all
    vnet_route_all_enabled = lookup(each.value, "vnet_route_all_enabled", true)

    # IP restrictions
    dynamic "ip_restriction" {
      for_each = lookup(each.value, "ip_restrictions", [])
      content {
        name                      = ip_restriction.value.name
        priority                  = ip_restriction.value.priority
        action                    = ip_restriction.value.action
        ip_address                = lookup(ip_restriction.value, "ip_address", null)
        virtual_network_subnet_id = lookup(ip_restriction.value, "virtual_network_subnet_id", null)
        service_tag               = lookup(ip_restriction.value, "service_tag", null)
      }
    }

    # Application stack configuration
    dynamic "application_stack" {
      for_each = lookup(each.value, "application_stack", null) != null ? [each.value.application_stack] : []
      content {
        docker_image_name        = lookup(application_stack.value, "docker_image_name", null)
        docker_registry_url      = lookup(application_stack.value, "docker_registry_url", null)
        docker_registry_username = lookup(application_stack.value, "docker_registry_username", null)
        docker_registry_password = lookup(application_stack.value, "docker_registry_password", null)
        dotnet_version           = lookup(application_stack.value, "dotnet_version", null)
        java_server              = lookup(application_stack.value, "java_server", null)
        java_server_version      = lookup(application_stack.value, "java_server_version", null)
        java_version             = lookup(application_stack.value, "java_version", null)
        node_version             = lookup(application_stack.value, "node_version", null)
        php_version              = lookup(application_stack.value, "php_version", null)
        python_version           = lookup(application_stack.value, "python_version", null)
        ruby_version             = lookup(application_stack.value, "ruby_version", null)
        go_version               = lookup(application_stack.value, "go_version", null)
      }
    }

    # CORS configuration
    dynamic "cors" {
      for_each = lookup(each.value, "cors", null) != null ? [each.value.cors] : []
      content {
        allowed_origins     = cors.value.allowed_origins
        support_credentials = lookup(cors.value, "support_credentials", false)
      }
    }
  }

  # App settings
  app_settings = merge(
    var.common_app_settings,
    lookup(each.value, "app_settings", {})
  )

  # Connection strings
  dynamic "connection_string" {
    for_each = lookup(each.value, "connection_strings", [])
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  # Storage account mounts
  dynamic "storage_account" {
    for_each = lookup(each.value, "storage_mounts", [])
    content {
      name         = storage_account.value.name
      type         = storage_account.value.type
      account_name = storage_account.value.account_name
      share_name   = storage_account.value.share_name
      access_key   = storage_account.value.access_key
      mount_path   = storage_account.value.mount_path
    }
  }

  # Logging configuration
  logs {
    detailed_error_messages = lookup(each.value, "detailed_error_messages", true)
    failed_request_tracing  = lookup(each.value, "failed_request_tracing", true)

    dynamic "http_logs" {
      for_each = lookup(each.value, "http_logs", null) != null ? [each.value.http_logs] : []
      content {
        dynamic "file_system" {
          for_each = lookup(http_logs.value, "file_system", null) != null ? [http_logs.value.file_system] : []
          content {
            retention_in_days = file_system.value.retention_in_days
            retention_in_mb   = file_system.value.retention_in_mb
          }
        }
        dynamic "azure_blob_storage" {
          for_each = lookup(http_logs.value, "azure_blob_storage", null) != null ? [http_logs.value.azure_blob_storage] : []
          content {
            sas_url           = azure_blob_storage.value.sas_url
            retention_in_days = azure_blob_storage.value.retention_in_days
          }
        }
      }
    }

    dynamic "application_logs" {
      for_each = lookup(each.value, "application_logs", null) != null ? [each.value.application_logs] : []
      content {
        file_system_level = lookup(application_logs.value, "file_system_level", "Information")
        dynamic "azure_blob_storage" {
          for_each = lookup(application_logs.value, "azure_blob_storage", null) != null ? [application_logs.value.azure_blob_storage] : []
          content {
            level             = azure_blob_storage.value.level
            sas_url           = azure_blob_storage.value.sas_url
            retention_in_days = azure_blob_storage.value.retention_in_days
          }
        }
      }
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
      app_settings["DOCKER_REGISTRY_SERVER_PASSWORD"],
    ]
  }
}

# ─────────────────────────────────────────────────────────────
# Windows Web Apps
# ─────────────────────────────────────────────────────────────
resource "azurerm_windows_web_app" "main" {
  for_each = var.os_type == "Windows" ? var.app_configs : {}

  name                = "app-${var.project_name}-${each.key}-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.main.id

  # HTTPS enforcement
  https_only = true

  # Client certificate mode
  client_certificate_enabled = lookup(each.value, "client_certificate_enabled", false)
  client_certificate_mode    = lookup(each.value, "client_certificate_mode", "Optional")

  # Virtual Network Integration
  virtual_network_subnet_id = var.vnet_integration_subnet_id

  # Managed Identity
  identity {
    type         = var.identity_type
    identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.user_assigned_identity_ids : null
  }

  site_config {
    # Always On for production
    always_on = lookup(each.value, "always_on", true)

    # HTTP/2 support
    http2_enabled = lookup(each.value, "http2_enabled", true)

    # Minimum TLS version
    minimum_tls_version = lookup(each.value, "minimum_tls_version", "1.2")

    # FTP state
    ftps_state = lookup(each.value, "ftps_state", "Disabled")

    # Health check
    health_check_path                 = lookup(each.value, "health_check_path", null)
    health_check_eviction_time_in_min = lookup(each.value, "health_check_eviction_time_in_min", 10)

    # VNet route all
    vnet_route_all_enabled = lookup(each.value, "vnet_route_all_enabled", true)

    # IP restrictions
    dynamic "ip_restriction" {
      for_each = lookup(each.value, "ip_restrictions", [])
      content {
        name                      = ip_restriction.value.name
        priority                  = ip_restriction.value.priority
        action                    = ip_restriction.value.action
        ip_address                = lookup(ip_restriction.value, "ip_address", null)
        virtual_network_subnet_id = lookup(ip_restriction.value, "virtual_network_subnet_id", null)
        service_tag               = lookup(ip_restriction.value, "service_tag", null)
      }
    }

    # Application stack configuration
    dynamic "application_stack" {
      for_each = lookup(each.value, "application_stack", null) != null ? [each.value.application_stack] : []
      content {
        current_stack             = lookup(application_stack.value, "current_stack", null)
        docker_image_name         = lookup(application_stack.value, "docker_image_name", null)
        docker_registry_url       = lookup(application_stack.value, "docker_registry_url", null)
        docker_registry_username  = lookup(application_stack.value, "docker_registry_username", null)
        docker_registry_password  = lookup(application_stack.value, "docker_registry_password", null)
        dotnet_version            = lookup(application_stack.value, "dotnet_version", null)
        dotnet_core_version       = lookup(application_stack.value, "dotnet_core_version", null)
        java_version              = lookup(application_stack.value, "java_version", null)
        java_embedded_server_enabled = lookup(application_stack.value, "java_embedded_server_enabled", null)
        node_version              = lookup(application_stack.value, "node_version", null)
        php_version               = lookup(application_stack.value, "php_version", null)
        python                    = lookup(application_stack.value, "python", null)
      }
    }

    # CORS configuration
    dynamic "cors" {
      for_each = lookup(each.value, "cors", null) != null ? [each.value.cors] : []
      content {
        allowed_origins     = cors.value.allowed_origins
        support_credentials = lookup(cors.value, "support_credentials", false)
      }
    }
  }

  # App settings
  app_settings = merge(
    var.common_app_settings,
    lookup(each.value, "app_settings", {})
  )

  # Connection strings
  dynamic "connection_string" {
    for_each = lookup(each.value, "connection_strings", [])
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  # Storage account mounts
  dynamic "storage_account" {
    for_each = lookup(each.value, "storage_mounts", [])
    content {
      name         = storage_account.value.name
      type         = storage_account.value.type
      account_name = storage_account.value.account_name
      share_name   = storage_account.value.share_name
      access_key   = storage_account.value.access_key
      mount_path   = storage_account.value.mount_path
    }
  }

  # Logging configuration
  logs {
    detailed_error_messages = lookup(each.value, "detailed_error_messages", true)
    failed_request_tracing  = lookup(each.value, "failed_request_tracing", true)

    dynamic "http_logs" {
      for_each = lookup(each.value, "http_logs", null) != null ? [each.value.http_logs] : []
      content {
        dynamic "file_system" {
          for_each = lookup(http_logs.value, "file_system", null) != null ? [http_logs.value.file_system] : []
          content {
            retention_in_days = file_system.value.retention_in_days
            retention_in_mb   = file_system.value.retention_in_mb
          }
        }
        dynamic "azure_blob_storage" {
          for_each = lookup(http_logs.value, "azure_blob_storage", null) != null ? [http_logs.value.azure_blob_storage] : []
          content {
            sas_url           = azure_blob_storage.value.sas_url
            retention_in_days = azure_blob_storage.value.retention_in_days
          }
        }
      }
    }

    dynamic "application_logs" {
      for_each = lookup(each.value, "application_logs", null) != null ? [each.value.application_logs] : []
      content {
        file_system_level = lookup(application_logs.value, "file_system_level", "Information")
        dynamic "azure_blob_storage" {
          for_each = lookup(application_logs.value, "azure_blob_storage", null) != null ? [application_logs.value.azure_blob_storage] : []
          content {
            level             = azure_blob_storage.value.level
            sas_url           = azure_blob_storage.value.sas_url
            retention_in_days = azure_blob_storage.value.retention_in_days
          }
        }
      }
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
      app_settings["DOCKER_REGISTRY_SERVER_PASSWORD"],
    ]
  }
}

# ─────────────────────────────────────────────────────────────
# Private Endpoints for App Services
# ─────────────────────────────────────────────────────────────
resource "azurerm_private_endpoint" "linux_apps" {
  for_each = var.enable_private_endpoint && var.os_type == "Linux" ? var.app_configs : {}

  name                = "pe-${azurerm_linux_web_app.main[each.key].name}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_linux_web_app.main[each.key].name}"
    private_connection_resource_id = azurerm_linux_web_app.main[each.key].id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "windows_apps" {
  for_each = var.enable_private_endpoint && var.os_type == "Windows" ? var.app_configs : {}

  name                = "pe-${azurerm_windows_web_app.main[each.key].name}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_windows_web_app.main[each.key].name}"
    private_connection_resource_id = azurerm_windows_web_app.main[each.key].id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────
# Diagnostic Settings for App Service Plan
# ─────────────────────────────────────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "app_service_plan" {
  count = var.enable_diagnostics && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${azurerm_service_plan.main.name}"
  target_resource_id         = azurerm_service_plan.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# ─────────────────────────────────────────────────────────────
# Diagnostic Settings for Linux Web Apps
# ─────────────────────────────────────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "linux_apps" {
  for_each = var.enable_diagnostics && var.log_analytics_workspace_id != null && var.os_type == "Linux" ? var.app_configs : {}

  name                       = "diag-${azurerm_linux_web_app.main[each.key].name}"
  target_resource_id         = azurerm_linux_web_app.main[each.key].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServiceAuditLogs"
  }

  enabled_log {
    category = "AppServiceIPSecAuditLogs"
  }

  enabled_log {
    category = "AppServicePlatformLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# ─────────────────────────────────────────────────────────────
# Diagnostic Settings for Windows Web Apps
# ─────────────────────────────────────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "windows_apps" {
  for_each = var.enable_diagnostics && var.log_analytics_workspace_id != null && var.os_type == "Windows" ? var.app_configs : {}

  name                       = "diag-${azurerm_windows_web_app.main[each.key].name}"
  target_resource_id         = azurerm_windows_web_app.main[each.key].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServiceAuditLogs"
  }

  enabled_log {
    category = "AppServiceIPSecAuditLogs"
  }

  enabled_log {
    category = "AppServicePlatformLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
