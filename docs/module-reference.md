# Module Reference

This document provides detailed information about each Terraform module in this solution.

## Module Overview

| Module | Description | Key Resources |
|--------|-------------|---------------|
| resource_group | Creates the Azure Resource Group | azurerm_resource_group |
| virtualnetwork | Creates the Virtual Network | azurerm_virtual_network |
| virtualsubnet | Creates subnets with delegations | azurerm_subnet |
| securitygroup | Creates NSGs and rules | azurerm_network_security_group |
| key_vault | Key Vault with private endpoint | azurerm_key_vault, azurerm_private_endpoint |
| cosmos_db | Cosmos DB with private endpoint | azurerm_cosmosdb_account, azurerm_private_endpoint |
| function_app | Function App with VNet integration | azurerm_linux_function_app, azurerm_private_endpoint |
| static_web_app | Static Web App | azurerm_static_web_app |
| log_analytics | Log Analytics workspace | azurerm_log_analytics_workspace |
| app_insights | Application Insights | azurerm_application_insights |

---

## resource_group

Creates an Azure Resource Group to contain all resources.

### Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| resource_group_name | string | Yes | Name of the resource group |
| location | string | Yes | Azure region |
| tags | map(string) | No | Resource tags |

### Outputs

| Name | Description |
|------|-------------|
| name | Resource group name |
| id | Resource group ID |
| location | Resource group location |

---

## virtualnetwork

Creates an Azure Virtual Network.

### Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | Yes | VNet name |
| resource_group_name | string | Yes | Resource group name |
| location | string | Yes | Azure region |
| address_space | list(string) | Yes | VNet address space |
| tags | map(string) | No | Resource tags |

### Outputs

| Name | Description |
|------|-------------|
| id | VNet resource ID |
| name | VNet name |

---

## virtualsubnet

Creates subnets within a VNet, including delegations and service endpoints.

### Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| resource_group_name | string | Yes | Resource group name |
| vnet_name | string | Yes | Virtual network name |
| environment | string | Yes | Environment name |
| address_prefix_base | string | No | Base address prefix (default: "10.0") |

### Subnet Configuration

The module creates these subnets by default:

```hcl
subnet_configs = {
  function_app = {
    address_prefix    = "10.x.1.0/24"
    service_endpoints = ["Microsoft.Web", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.AzureCosmosDB"]
    delegation        = "Microsoft.Web/serverFarms"
  }
  app_service = {
    address_prefix    = "10.x.2.0/24"
    service_endpoints = ["Microsoft.Web", "Microsoft.KeyVault"]
    delegation        = "Microsoft.Web/serverFarms"
  }
  private_endpoints = {
    address_prefix    = "10.x.3.0/24"
    service_endpoints = []
    delegation        = null
  }
  data = {
    address_prefix    = "10.x.4.0/24"
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.AzureCosmosDB"]
    delegation        = null
  }
}
```

### Outputs

| Name | Description |
|------|-------------|
| subnets | Map of subnet objects |
| subnet_ids | Map of subnet name to ID |

---

## securitygroup

Creates Network Security Groups and associates them with subnets.

### Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| resource_group_name | string | Yes | Resource group name |
| environment | string | Yes | Environment name |
| subnet_configs | map | Yes | Map of subnet configurations |
| subnet_ids | map | Yes | Map of subnet IDs |
| tags | map(string) | No | Resource tags |

### NSG Rules Created

- Function App: Allow HTTPS inbound from AppService, Allow outbound to VNet, Deny all
- Private Endpoints: Allow VNet inbound, Deny all
- App Service: Allow HTTPS inbound, Allow outbound to VNet

### Outputs

| Name | Description |
|------|-------------|
| nsg_ids | Map of NSG name to ID |

---

## key_vault

Creates an Azure Key Vault with private endpoint and network ACLs.

### Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | Yes | Key Vault name |
| location | string | Yes | Azure region |
| resource_group_name | string | Yes | Resource group name |
| tenant_id | string | Yes | Azure AD tenant ID |
| private_endpoint_subnet_id | string | Yes | Subnet ID for private endpoint |
| allowed_subnet_ids | list(string) | Yes | Subnets allowed via service endpoints |
| enable_diagnostics | bool | No | Enable diagnostic settings |
| log_analytics_workspace_id | string | No | Log Analytics workspace ID |
| tags | map(string) | No | Resource tags |

### Security Features

- Soft delete enabled (90 days retention)
- Purge protection enabled
- Public network access disabled
- RBAC authorization enabled
- Private endpoint created
- Network ACLs with deny default

### Outputs

| Name | Description |
|------|-------------|
| id | Key Vault resource ID |
| name | Key Vault name |
| uri | Key Vault URI |

---

## cosmos_db

Creates an Azure Cosmos DB account with SQL API, private endpoint, and VNet filtering.

### Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | Yes | Cosmos DB account name |
| location | string | Yes | Azure region |
| resource_group_name | string | Yes | Resource group name |
| database_name | string | No | Database name (default: "employeedb") |
| container_name | string | No | Container name (default: "employees") |
| partition_key_path | string | No | Partition key (default: "/departmentId") |
| throughput | number | No | Provisioned RUs (default: 400) |
| private_endpoint_subnet_id | string | Yes | Subnet ID for private endpoint |
| allowed_subnet_ids | list(string) | Yes | Subnets allowed via service endpoints |
| enable_diagnostics | bool | No | Enable diagnostic settings |
| log_analytics_workspace_id | string | No | Log Analytics workspace ID |
| tags | map(string) | No | Resource tags |

### Security Features

- Public network access disabled
- VNet filtering enabled
- Private endpoint created
- Virtual network rules for allowed subnets

### Outputs

| Name | Description |
|------|-------------|
| id | Cosmos DB account ID |
| endpoint | Cosmos DB endpoint URL |
| database_name | Database name |
| container_name | Container name |

---

## function_app

Creates an Azure Function App with VNet integration, storage account, and private endpoints.

### Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | Yes | Function App name |
| location | string | Yes | Azure region |
| resource_group_name | string | Yes | Resource group name |
| storage_account_name | string | Yes | Storage account name |
| python_version | string | No | Python version (default: "3.11") |
| app_settings | map(string) | No | Application settings |
| app_insights_connection_string | string | No | App Insights connection string |
| private_endpoint_subnet_id | string | Yes | Subnet ID for private endpoints |
| vnet_integration_subnet_id | string | Yes | Subnet ID for VNet integration |
| tags | map(string) | No | Resource tags |

### Resources Created

1. Storage Account (with network rules)
2. Storage File Share (for function content)
3. Private Endpoint for Storage (Blob)
4. Private Endpoint for Storage (File)
5. App Service Plan (Elastic Premium EP1)
6. Linux Function App
7. Private Endpoint for Function App

### Security Features

- Storage account: Public access disabled, network ACLs
- Function App: Public access disabled, VNet integration
- All traffic routed through VNet (WEBSITE_VNET_ROUTE_ALL=1)
- Content stored over VNet (WEBSITE_CONTENTOVERVNET=1)

### Outputs

| Name | Description |
|------|-------------|
| id | Function App resource ID |
| name | Function App name |
| hostname | Default hostname |
| principal_id | Managed identity principal ID |

---

## static_web_app

Creates an Azure Static Web App for hosting the frontend.

### Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | Yes | Static Web App name |
| location | string | Yes | Azure region |
| resource_group_name | string | Yes | Resource group name |
| sku_tier | string | No | SKU tier (default: "Free") |
| sku_size | string | No | SKU size (default: "Free") |
| tags | map(string) | No | Resource tags |

### Outputs

| Name | Description |
|------|-------------|
| id | Static Web App resource ID |
| name | Static Web App name |
| hostname | Default hostname |
| api_key | API key for deployment (sensitive) |

---

## log_analytics

Creates a Log Analytics workspace for centralized logging.

### Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | Yes | Workspace name |
| location | string | Yes | Azure region |
| resource_group_name | string | Yes | Resource group name |
| retention_in_days | number | No | Log retention (default: 30) |
| tags | map(string) | No | Resource tags |

### Outputs

| Name | Description |
|------|-------------|
| id | Workspace resource ID |
| workspace_id | Workspace ID (GUID) |

---

## app_insights

Creates an Application Insights resource for application monitoring.

### Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | Yes | App Insights name |
| location | string | Yes | Azure region |
| resource_group_name | string | Yes | Resource group name |
| log_analytics_workspace_id | string | Yes | Log Analytics workspace ID |
| tags | map(string) | No | Resource tags |

### Outputs

| Name | Description |
|------|-------------|
| id | App Insights resource ID |
| instrumentation_key | Instrumentation key (sensitive) |
| connection_string | Connection string (sensitive) |
