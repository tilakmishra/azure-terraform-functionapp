# ─────────────────────────────────────────────────────────────
# Azure App Service Module - Outputs
# ─────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────
# App Service Plan Outputs
# ─────────────────────────────────────────────────────────────
output "app_service_plan_id" {
  description = "App Service Plan ID"
  value       = azurerm_service_plan.main.id
}

output "app_service_plan_name" {
  description = "App Service Plan name"
  value       = azurerm_service_plan.main.name
}

output "app_service_plan_kind" {
  description = "App Service Plan kind (linux/windows)"
  value       = azurerm_service_plan.main.kind
}

# ─────────────────────────────────────────────────────────────
# Linux Web App Outputs
# ─────────────────────────────────────────────────────────────
output "linux_web_apps" {
  description = "Map of Linux Web Apps with their details"
  value = var.os_type == "Linux" ? {
    for key, app in azurerm_linux_web_app.main : key => {
      id                             = app.id
      name                           = app.name
      default_hostname               = app.default_hostname
      outbound_ip_addresses          = app.outbound_ip_addresses
      possible_outbound_ip_addresses = app.possible_outbound_ip_addresses
      identity = {
        principal_id = try(app.identity[0].principal_id, null)
        tenant_id    = try(app.identity[0].tenant_id, null)
      }
    }
  } : {}
}

output "linux_web_app_ids" {
  description = "Map of Linux Web App IDs"
  value = var.os_type == "Linux" ? {
    for key, app in azurerm_linux_web_app.main : key => app.id
  } : {}
}

output "linux_web_app_hostnames" {
  description = "Map of Linux Web App default hostnames"
  value = var.os_type == "Linux" ? {
    for key, app in azurerm_linux_web_app.main : key => app.default_hostname
  } : {}
}

output "linux_web_app_identities" {
  description = "Map of Linux Web App managed identity principal IDs"
  value = var.os_type == "Linux" ? {
    for key, app in azurerm_linux_web_app.main : key => try(app.identity[0].principal_id, null)
  } : {}
}

# ─────────────────────────────────────────────────────────────
# Windows Web App Outputs
# ─────────────────────────────────────────────────────────────
output "windows_web_apps" {
  description = "Map of Windows Web Apps with their details"
  value = var.os_type == "Windows" ? {
    for key, app in azurerm_windows_web_app.main : key => {
      id                             = app.id
      name                           = app.name
      default_hostname               = app.default_hostname
      outbound_ip_addresses          = app.outbound_ip_addresses
      possible_outbound_ip_addresses = app.possible_outbound_ip_addresses
      identity = {
        principal_id = try(app.identity[0].principal_id, null)
        tenant_id    = try(app.identity[0].tenant_id, null)
      }
    }
  } : {}
}

output "windows_web_app_ids" {
  description = "Map of Windows Web App IDs"
  value = var.os_type == "Windows" ? {
    for key, app in azurerm_windows_web_app.main : key => app.id
  } : {}
}

output "windows_web_app_hostnames" {
  description = "Map of Windows Web App default hostnames"
  value = var.os_type == "Windows" ? {
    for key, app in azurerm_windows_web_app.main : key => app.default_hostname
  } : {}
}

output "windows_web_app_identities" {
  description = "Map of Windows Web App managed identity principal IDs"
  value = var.os_type == "Windows" ? {
    for key, app in azurerm_windows_web_app.main : key => try(app.identity[0].principal_id, null)
  } : {}
}

# ─────────────────────────────────────────────────────────────
# Combined Outputs (works for both Linux and Windows)
# ─────────────────────────────────────────────────────────────
output "web_app_ids" {
  description = "Map of all Web App IDs (Linux or Windows based on os_type)"
  value = var.os_type == "Linux" ? {
    for key, app in azurerm_linux_web_app.main : key => app.id
    } : {
    for key, app in azurerm_windows_web_app.main : key => app.id
  }
}

output "web_app_hostnames" {
  description = "Map of all Web App default hostnames (Linux or Windows based on os_type)"
  value = var.os_type == "Linux" ? {
    for key, app in azurerm_linux_web_app.main : key => app.default_hostname
    } : {
    for key, app in azurerm_windows_web_app.main : key => app.default_hostname
  }
}

output "web_app_identities" {
  description = "Map of all Web App managed identity principal IDs (Linux or Windows based on os_type)"
  value = var.os_type == "Linux" ? {
    for key, app in azurerm_linux_web_app.main : key => try(app.identity[0].principal_id, null)
    } : {
    for key, app in azurerm_windows_web_app.main : key => try(app.identity[0].principal_id, null)
  }
}

# ─────────────────────────────────────────────────────────────
# Private Endpoint Outputs
# ─────────────────────────────────────────────────────────────
output "private_endpoint_ids" {
  description = "Map of private endpoint IDs"
  value = var.enable_private_endpoint ? (
    var.os_type == "Linux" ? {
      for key, pe in azurerm_private_endpoint.linux_apps : key => pe.id
      } : {
      for key, pe in azurerm_private_endpoint.windows_apps : key => pe.id
    }
  ) : {}
}

output "private_endpoint_ip_addresses" {
  description = "Map of private endpoint private IP addresses"
  value = var.enable_private_endpoint ? (
    var.os_type == "Linux" ? {
      for key, pe in azurerm_private_endpoint.linux_apps : key => pe.private_service_connection[0].private_ip_address
      } : {
      for key, pe in azurerm_private_endpoint.windows_apps : key => pe.private_service_connection[0].private_ip_address
    }
  ) : {}
}
