# ═══════════════════════════════════════════════════════════════════════════════
# DTE Web Application - Main Configuration
# ═══════════════════════════════════════════════════════════════════════════════
# Description: This file has been split into separate resource-specific .tf files
#              following enterprise best practices for better maintainability.
#
# Resource Files:
#   - resourceGroup.tf    : Resource Group module
#   - virtualNetwork.tf   : Virtual Network module
#   - virtualSubnet.tf    : Subnet configuration
#   - securityGroup.tf    : Network Security Groups
#   - logAnalytics.tf     : Log Analytics Workspace
#   - appInsights.tf      : Application Insights
#   - keyVault.tf         : Key Vault for secrets
#   - cosmosDb.tf         : Cosmos DB database
#   - functionApp.tf      : Function App API
#   - staticWebApp.tf     : Static Web App frontend
#   - rbac.tf             : Role assignments
#   - data.tf             : Data sources
#
# Supporting Files:
#   - versions.tf         : Terraform and provider versions
#   - provider.tf         : Provider configuration
#   - variables.tf        : Input variables
#   - locals.tf           : Local values and naming
#   - outputs.tf          : Output values
#   - dev.tfvars          : Development environment config
#   - prod.tfvars         : Production environment config
#
# ═══════════════════════════════════════════════════════════════════════════════
