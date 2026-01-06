# ═══════════════════════════════════════════════════════════════════════════════
# DTE Employee Management Web Application - Main Terraform Configuration
# ═══════════════════════════════════════════════════════════════════════════════
# This file orchestrates all infrastructure modules following Terraform best practices:
# - Uses underscore naming conventions (not dashes)
# - Resources with meaningful names (no type repetition)
# - All module calls centralized here for clarity
# - Environment-specific values in tfvars files (no hardcoding)
# 
# ─────────────────────────────────────────────────────────────────────────────
# Deployment Instructions:
# ─────────────────────────────────────────────────────────────────────────────
# Development:
#   terraform init
#   terraform plan -var-file="environments/common.tfvars" -var-file="environments/dev.tfvars"
#   terraform apply -var-file="environments/common.tfvars" -var-file="environments/dev.tfvars"
#
# Staging:
#   terraform plan -var-file="environments/common.tfvars" -var-file="environments/stg.tfvars"
#   terraform apply -var-file="environments/common.tfvars" -var-file="environments/stg.tfvars"
#
# Production:
#   terraform plan -var-file="environments/common.tfvars" -var-file="environments/prod.tfvars"
#   terraform apply -var-file="environments/common.tfvars" -var-file="environments/prod.tfvars"
# ═══════════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────────────────
# Foundation Layer - Core Infrastructure
# ─────────────────────────────────────────────────────────────────────────────

module "resource_group" {
  source = "./modules/resource_group"

  resource_group_name = local.resource_group_name
  location            = var.azure_region
  tags                = local.common_tags
}

module "log_analytics" {
  source = "./modules/log_analytics"

  count = var.enable_monitoring ? 1 : 0

  name                = "log_${local.name_prefix}"
  location            = var.azure_region
  resource_group_name = module.resource_group.name
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags

  depends_on = [module.resource_group]
}

module "app_insights" {
  source = "./modules/app_insights"

  count = var.enable_monitoring ? 1 : 0

  name                       = "appi_${local.name_prefix}"
  location                   = var.azure_region
  resource_group_name        = module.resource_group.name
  log_analytics_workspace_id = module.log_analytics[0].workspace_id
  retention_in_days          = var.log_retention_days
  tags                       = local.common_tags

  depends_on = [module.log_analytics]
}

# ─────────────────────────────────────────────────────────────────────────────
# Networking Layer - VNet, Subnets, NSGs, Private DNS
# ─────────────────────────────────────────────────────────────────────────────

module "virtualnetwork" {
  source = "./modules/virtualnetwork"

  name                = "vnet_${local.name_prefix}"
  location            = var.azure_region
  resource_group_name = module.resource_group.name
  address_space       = var.vnet_address_space
  tags                = local.common_tags

  depends_on = [module.resource_group]
}

module "virtualsubnet" {
  source = "./modules/virtualsubnet"

  environment         = var.environment
  resource_group_name = module.resource_group.name
  vnet_name           = module.virtualnetwork.name

  # Subnet configurations use environment-specific CIDR blocks from tfvars
  # This prevents CIDR collisions across dev, stg, and prod environments
  subnet_configs = {
    function_app = {
      address_prefixes  = [var.subnet_function_app_cidr]
      service_endpoints = ["Microsoft.Web", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.AzureCosmosDB"]
      delegation = {
        name         = "function-app-delegation"
        service_name = "Microsoft.Web/serverFarms"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    private_endpoints = {
      address_prefixes  = [var.subnet_private_endpoints_cidr]
      service_endpoints = []
    }
    data = {
      address_prefixes  = [var.subnet_data_cidr]
      service_endpoints = ["Microsoft.AzureCosmosDB", "Microsoft.KeyVault", "Microsoft.Storage"]
    }
  }

  depends_on = [module.virtualnetwork]
}

module "securitygroup" {
  source = "./modules/securitygroup"

  resource_group_name = module.resource_group.name
  environment         = var.environment
  subnet_configs = {
    for key, subnet in module.virtualsubnet.subnets : key => {
      address_prefixes  = subnet.address_prefixes
      service_endpoints = subnet.service_endpoints
    }
  }
  subnet_ids = module.virtualsubnet.subnet_ids
  tags       = local.common_tags

  depends_on = [module.virtualsubnet]
}

module "cosmos_private_dns_zone" {
  source = "./modules/private_dns_zone"

  zone_name           = "privatelink.documents.azure.com"
  resource_group_name = module.resource_group.name
  virtual_network_id  = module.virtualnetwork.id
  tags                = local.common_tags

  depends_on = [module.virtualnetwork]
}

# ─────────────────────────────────────────────────────────────────────────────
# Security Layer - Key Vault
# ─────────────────────────────────────────────────────────────────────────────

module "key_vault" {
  source = "./modules/key_vault"

  name                       = local.key_vault_name
  location                   = var.azure_region
  resource_group_name        = module.resource_group.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  private_endpoint_subnet_id = module.virtualsubnet.subnet_ids["private_endpoints"]
  allowed_subnet_ids         = [module.virtualsubnet.subnet_ids["function_app"]]
  tags                       = local.common_tags

  depends_on = [module.securitygroup]
}

# ─────────────────────────────────────────────────────────────────────────────
# Database Layer - Cosmos DB
# ─────────────────────────────────────────────────────────────────────────────

module "cosmos_db" {
  source = "./modules/cosmos_db"

  name                       = local.cosmos_db_name
  location                   = var.azure_region
  resource_group_name        = module.resource_group.name
  database_name              = "EmployeeDB"
  container_name             = "Employees"
  partition_key_path         = "/id"
  throughput                 = var.cosmos_db_throughput
  allowed_subnet_ids         = [module.virtualsubnet.subnet_ids["function_app"], module.virtualsubnet.subnet_ids["data"]]
  private_endpoint_subnet_id = module.virtualsubnet.subnet_ids["private_endpoints"]
  private_dns_zone_id        = module.cosmos_private_dns_zone.id
  enable_diagnostics         = var.enable_monitoring
  log_analytics_workspace_id = var.enable_monitoring ? module.log_analytics[0].workspace_id : null
  tags                       = local.common_tags

  depends_on = [module.cosmos_private_dns_zone, module.securitygroup]
}

# ─────────────────────────────────────────────────────────────────────────────
# Compute Layer - Function App (Backend API)
# ─────────────────────────────────────────────────────────────────────────────

module "function_app" {
  source = "./modules/function_app"

  name                           = local.function_app_name
  location                       = var.azure_region
  resource_group_name            = module.resource_group.name
  storage_account_name           = local.storage_account_name
  vnet_integration_subnet_id     = module.virtualsubnet.subnet_ids["function_app"]
  private_endpoint_subnet_id     = module.virtualsubnet.subnet_ids["private_endpoints"]
  app_insights_connection_string = var.enable_monitoring ? try(module.app_insights[0].connection_string, "") : ""
  python_version                 = var.function_app_runtime_version
  tags                           = local.common_tags

  depends_on = [module.app_insights, module.securitygroup]
}

# ─────────────────────────────────────────────────────────────────────────────
# Frontend Layer - Static Web App
# ─────────────────────────────────────────────────────────────────────────────

module "static_web_app" {
  source = "./modules/static_web_app"

  name                = local.static_web_app_name
  location            = var.azure_region
  resource_group_name = module.resource_group.name
  tags                = local.common_tags

  depends_on = [module.resource_group]
}

# ─────────────────────────────────────────────────────────────────────────────
# RBAC Layer - Identity & Access Management
# ─────────────────────────────────────────────────────────────────────────────

# Grant Function App managed identity access to Cosmos DB
resource "azurerm_cosmosdb_sql_role_assignment" "function_app_cosmos_access" {
  resource_group_name = module.resource_group.name
  account_name        = module.cosmos_db.name
  role_definition_id  = "${module.cosmos_db.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002" # Cosmos DB Built-in Data Contributor
  principal_id        = module.function_app.identity_principal_id
  scope               = module.cosmos_db.id

  depends_on = [module.function_app, module.cosmos_db]
}

# Grant Function App managed identity access to Key Vault secrets
resource "azurerm_role_assignment" "function_app_keyvault_access" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.function_app.identity_principal_id

  depends_on = [module.function_app, module.key_vault]
}
