# ═══════════════════════════════════════════════════════════════════════════════
# DTE Web Application - Development Environment
# ═══════════════════════════════════════════════════════════════════════════════
# Usage: terraform apply -var-file="dev.tfvars"
# ═══════════════════════════════════════════════════════════════════════════════

# Core Settings
environment  = "dev"
azure_region = "eastus2"
project_name = "emp"

# Tagging
owner_email = "team@company.com"
cost_center = "IT"

# Networking (VNet & Private Endpoints always enabled for security)
vnet_address_space = ["10.0.0.0/16"]

# Cosmos DB
cosmos_db_throughput = 400  # Minimum for dev

# Function App
function_app_runtime         = "python"
function_app_runtime_version = "3.11"

# Monitoring
enable_monitoring  = true
log_retention_days = 30

# Resource Naming (dev uses random suffix - do not set unique_suffix)
