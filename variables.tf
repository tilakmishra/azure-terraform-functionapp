# ═══════════════════════════════════════════════════════════════════════════════
# DTE Web Application - Variables (Simplified MVP)
# ═══════════════════════════════════════════════════════════════════════════════
# Description: Simple variable definitions for the DTE web application
# ═══════════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────────────────
# Required Variables (Must be provided)
# ─────────────────────────────────────────────────────────────────────────────
variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
}

variable "azure_region" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "eastus2"
}

# ─────────────────────────────────────────────────────────────────────────────
# Tagging Variables
# ─────────────────────────────────────────────────────────────────────────────
variable "owner_email" {
  description = "Email of the resource owner"
  type        = string
  default     = "team@company.com"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "IT"
}

variable "tags" {
  description = "Additional tags to apply"
  type        = map(string)
  default     = {}
}

# ─────────────────────────────────────────────────────────────────────────────
# Networking (VNet always enabled for enterprise security)
# ─────────────────────────────────────────────────────────────────────────────
variable "vnet_address_space" {
  description = "Virtual Network address space (CIDR blocks). Use different ranges per environment to avoid collisions (Dev: 10.0.0.0/16, Stg: 10.1.0.0/16, Prod: 10.2.0.0/16)"
  type        = list(string)
  nullable    = false
}

# ─────────────────────────────────────────────────────────────────────────────
# Subnet CIDR Blocks - Environment-Specific
# ─────────────────────────────────────────────────────────────────────────────
variable "subnet_function_app_cidr" {
  description = "CIDR block for Function App VNet integration subnet (e.g., 10.0.1.0/24 for dev, 10.1.1.0/24 for stg, 10.2.1.0/24 for prod)"
  type        = string
  nullable    = false
}

variable "subnet_private_endpoints_cidr" {
  description = "CIDR block for Private Endpoints subnet (e.g., 10.0.3.0/24 for dev, 10.1.3.0/24 for stg, 10.2.3.0/24 for prod)"
  type        = string
  nullable    = false
}

variable "subnet_data_cidr" {
  description = "CIDR block for Data subnet (e.g., 10.0.4.0/24 for dev, 10.1.4.0/24 for stg, 10.2.4.0/24 for prod)"
  type        = string
  nullable    = false
}

# ─────────────────────────────────────────────────────────────────────────────
# Storage
# ─────────────────────────────────────────────────────────────────────────────
variable "storage_account_name" {
  description = "Storage account name (leave empty for auto-generated)"
  type        = string
  default     = ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Cosmos DB
# ─────────────────────────────────────────────────────────────────────────────
variable "cosmos_db_throughput" {
  description = "Cosmos DB throughput in RU/s (400 minimum)"
  type        = number
  default     = 400
}

# ─────────────────────────────────────────────────────────────────────────────
# Function App
# ─────────────────────────────────────────────────────────────────────────────
variable "function_app_runtime" {
  description = "Function App runtime (python, node, dotnet)"
  type        = string
  default     = "python"
}

variable "function_app_runtime_version" {
  description = "Runtime version"
  type        = string
  default     = "3.11"
}

# ─────────────────────────────────────────────────────────────────────────────
# Monitoring
# ─────────────────────────────────────────────────────────────────────────────
variable "enable_monitoring" {
  description = "Enable Application Insights monitoring"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "How long to keep logs (days)"
  type        = number
  default     = 30
}

# ─────────────────────────────────────────────────────────────────────────────
# Resource Naming (Optional - for fixed naming in prod)
# ─────────────────────────────────────────────────────────────────────────────
variable "unique_suffix" {
  description = "Fixed unique suffix for resource names. Leave empty for auto-generated random suffix (recommended for dev)."
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "Fixed resource group name. Leave empty for auto-generated name."
  type        = string
  default     = ""
}

variable "key_vault_name" {
  description = "Fixed Key Vault name. Leave empty for auto-generated name."
  type        = string
  default     = ""
}

variable "cosmos_db_name" {
  description = "Fixed Cosmos DB account name. Leave empty for auto-generated name."
  type        = string
  default     = ""
}

variable "function_app_name" {
  description = "Fixed Function App name. Leave empty for auto-generated name."
  type        = string
  default     = ""
}

variable "static_web_app_name" {
  description = "Fixed Static Web App name. Leave empty for auto-generated name."
  type        = string
  default     = ""
}
