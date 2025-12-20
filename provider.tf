# ═══════════════════════════════════════════════════════════════════════════════
# DTE Web Application - Provider Configuration
# ═══════════════════════════════════════════════════════════════════════════════
# Description: Configures Azure providers with enterprise settings.
# ═══════════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────────────────
# Azure Resource Manager Provider
# ─────────────────────────────────────────────────────────────────────────────
provider "azurerm" {
  subscription_id = "016fb726-778a-499b-a880-2083ac9aeb06"
  
  features {
    # Key Vault settings
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    
    # Resource Group settings
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    
    # API Management settings
    api_management {
      purge_soft_delete_on_destroy = false
      recover_soft_deleted         = true
    }
    
    # Cognitive Services settings
    cognitive_account {
      purge_soft_delete_on_destroy = false
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Azure Active Directory Provider (for Entra ID)
# ─────────────────────────────────────────────────────────────────────────────
provider "azuread" {
  # Uses Azure CLI or environment credentials
}

