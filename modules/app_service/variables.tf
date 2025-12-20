# ─────────────────────────────────────────────────────────────
# Azure App Service Module - Input Variables
# ─────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────
# General Configuration
# ─────────────────────────────────────────────────────────────
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

# ─────────────────────────────────────────────────────────────
# App Service Plan Configuration
# ─────────────────────────────────────────────────────────────
variable "os_type" {
  description = "OS type for the App Service Plan (Linux or Windows)"
  type        = string
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "OS type must be either 'Linux' or 'Windows'."
  }
}

variable "sku_name" {
  description = "SKU name for the App Service Plan (e.g., B1, S1, P1v2, P1v3, P2v3, P3v3)"
  type        = string
  default     = "P1v3"

  validation {
    condition = contains([
      "F1", "D1", "B1", "B2", "B3",
      "S1", "S2", "S3",
      "P1v2", "P2v2", "P3v2",
      "P1v3", "P2v3", "P3v3",
      "P0v3", "P1mv3", "P2mv3", "P3mv3", "P4mv3", "P5mv3",
      "I1", "I2", "I3",
      "I1v2", "I2v2", "I3v2", "I4v2", "I5v2", "I6v2"
    ], var.sku_name)
    error_message = "Invalid SKU name. Please use a valid App Service Plan SKU."
  }
}

variable "zone_redundant" {
  description = "Enable zone redundancy for the App Service Plan (requires Premium v2/v3 SKU)"
  type        = bool
  default     = false
}

variable "worker_count" {
  description = "Number of workers (instances) for the App Service Plan"
  type        = number
  default     = 1
}

# ─────────────────────────────────────────────────────────────
# App Configurations
# ─────────────────────────────────────────────────────────────
variable "app_configs" {
  description = "Map of app configurations. Key is the app identifier."
  type = map(object({
    # Basic settings
    always_on                  = optional(bool, true)
    http2_enabled              = optional(bool, true)
    minimum_tls_version        = optional(string, "1.2")
    ftps_state                 = optional(string, "Disabled")
    client_certificate_enabled = optional(bool, false)
    client_certificate_mode    = optional(string, "Optional")

    # Health check
    health_check_path                 = optional(string)
    health_check_eviction_time_in_min = optional(number, 10)

    # Networking
    vnet_route_all_enabled = optional(bool, true)

    # IP restrictions
    ip_restrictions = optional(list(object({
      name                      = string
      priority                  = number
      action                    = string
      ip_address                = optional(string)
      virtual_network_subnet_id = optional(string)
      service_tag               = optional(string)
    })), [])

    # Application stack (Linux)
    application_stack = optional(object({
      docker_image_name        = optional(string)
      docker_registry_url      = optional(string)
      docker_registry_username = optional(string)
      docker_registry_password = optional(string)
      dotnet_version           = optional(string)
      java_server              = optional(string)
      java_server_version      = optional(string)
      java_version             = optional(string)
      node_version             = optional(string)
      php_version              = optional(string)
      python_version           = optional(string)
      ruby_version             = optional(string)
      go_version               = optional(string)
      # Windows specific
      current_stack                = optional(string)
      dotnet_core_version          = optional(string)
      java_embedded_server_enabled = optional(bool)
      python                       = optional(bool)
    }))

    # CORS
    cors = optional(object({
      allowed_origins     = list(string)
      support_credentials = optional(bool, false)
    }))

    # App settings
    app_settings = optional(map(string), {})

    # Connection strings
    connection_strings = optional(list(object({
      name  = string
      type  = string
      value = string
    })), [])

    # Storage mounts
    storage_mounts = optional(list(object({
      name         = string
      type         = string
      account_name = string
      share_name   = string
      access_key   = string
      mount_path   = string
    })), [])

    # Logging
    detailed_error_messages = optional(bool, true)
    failed_request_tracing  = optional(bool, true)

    http_logs = optional(object({
      file_system = optional(object({
        retention_in_days = number
        retention_in_mb   = number
      }))
      azure_blob_storage = optional(object({
        sas_url           = string
        retention_in_days = number
      }))
    }))

    application_logs = optional(object({
      file_system_level = optional(string, "Information")
      azure_blob_storage = optional(object({
        level             = string
        sas_url           = string
        retention_in_days = number
      }))
    }))
  }))
  default = {}
}

variable "common_app_settings" {
  description = "Common app settings applied to all apps"
  type        = map(string)
  default     = {}
}

# ─────────────────────────────────────────────────────────────
# Identity Configuration
# ─────────────────────────────────────────────────────────────
variable "identity_type" {
  description = "Type of managed identity (SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned)"
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "Identity type must be 'SystemAssigned', 'UserAssigned', or 'SystemAssigned, UserAssigned'."
  }
}

variable "user_assigned_identity_ids" {
  description = "List of User Assigned Managed Identity IDs"
  type        = list(string)
  default     = []
}

# ─────────────────────────────────────────────────────────────
# Networking Configuration
# ─────────────────────────────────────────────────────────────
variable "vnet_integration_subnet_id" {
  description = "Subnet ID for VNet integration (outbound traffic)"
  type        = string
  default     = null
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for the App Services"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS Zone ID for private endpoint DNS resolution"
  type        = string
  default     = null
}

# ─────────────────────────────────────────────────────────────
# Monitoring Configuration
# ─────────────────────────────────────────────────────────────
variable "enable_diagnostics" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostic settings"
  type        = string
  default     = null
}
