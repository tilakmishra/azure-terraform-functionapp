# ═══════════════════════════════════════════════════════════════════════════════
# DTE Web Application - Terraform Version & Backend Configuration
# ═══════════════════════════════════════════════════════════════════════════════
# Description: Defines Terraform version requirements, required providers,
#              and remote state backend configuration for enterprise deployment.
# Author:      DTE Platform Team
# Version:     1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

terraform {
  # ─────────────────────────────────────────────────────────────────────────────
  # Terraform Version Constraint
  # ─────────────────────────────────────────────────────────────────────────────
  required_version = ">= 1.5.0"

  # ─────────────────────────────────────────────────────────────────────────────
  # Remote State Backend Configuration
  # Uses Azure Storage Account for state management with encryption at rest
  # ─────────────────────────────────────────────────────────────────────────────
  # backend "azurerm" {
  #   resource_group_name  = "__tfResourceGroupName__"
  #   storage_account_name = "__tfStorageAccountName__"
  #   container_name       = "__tfContainerName__"
  #   key                  = "__tfStateFileName__"
  #   use_azuread_auth     = true  # Recommended: Use Azure AD auth instead of access keys
  # }

  # ─────────────────────────────────────────────────────────────────────────────
  # Required Providers
  # ─────────────────────────────────────────────────────────────────────────────
  required_providers {
    # Azure Resource Manager Provider
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    # Azure Active Directory Provider (for Entra ID)
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }

    # Random Provider (for unique naming)
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }

    # Time Provider (for time-based operations)
    time = {
      source  = "hashicorp/time"
      version = "~> 0.10"
    }
  }
}
