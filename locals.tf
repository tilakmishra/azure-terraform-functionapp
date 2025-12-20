# ═══════════════════════════════════════════════════════════════════════════════
# DTE Web Application - Local Values
# ═══════════════════════════════════════════════════════════════════════════════
# Description: Naming conventions and tags for all resources
# - Dev: Uses random suffix for unique names
# - Prod: Uses fixed values from variables for predictable naming
# ═══════════════════════════════════════════════════════════════════════════════

# Random string for unique resource names (only used if unique_suffix not provided)
resource "random_string" "unique" {
  length  = 4
  special = false
  upper   = false
  numeric = true
}

locals {
  # ─────────────────────────────────────────────────────────────────────────────
  # Environment Detection
  # ─────────────────────────────────────────────────────────────────────────────
  is_prod = var.environment == "prod"

  # ─────────────────────────────────────────────────────────────────────────────
  # Naming Convention
  # Dev: auto-generated with random suffix
  # Prod: fixed values from variables (or auto-generated if not provided)
  # ─────────────────────────────────────────────────────────────────────────────
  name_prefix   = "${var.project_name}-${var.environment}"
  unique_suffix = var.unique_suffix != "" ? var.unique_suffix : random_string.unique.result

  # Resource Names (use fixed if provided, otherwise generate)
  # Note: Function App, Static Web App need globally unique names - include suffix
  resource_group_name  = var.resource_group_name != "" ? var.resource_group_name : "rg-${local.name_prefix}"
  key_vault_name       = var.key_vault_name != "" ? var.key_vault_name : "kv-${local.name_prefix}-${local.unique_suffix}"
  cosmos_db_name       = var.cosmos_db_name != "" ? var.cosmos_db_name : "cosmos-${local.name_prefix}-${local.unique_suffix}"
  function_app_name    = var.function_app_name != "" ? var.function_app_name : "func-${local.name_prefix}-${local.unique_suffix}"
  static_web_app_name  = var.static_web_app_name != "" ? var.static_web_app_name : "swa-${local.name_prefix}-${local.unique_suffix}"
  storage_account_name = var.storage_account_name != "" ? var.storage_account_name : "st${replace(local.name_prefix, "-", "")}${local.unique_suffix}"

  # ─────────────────────────────────────────────────────────────────────────────
  # Standard Tags (Applied to all resources)
  # ─────────────────────────────────────────────────────────────────────────────
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner_email
    CostCenter  = var.cost_center
  }
}

