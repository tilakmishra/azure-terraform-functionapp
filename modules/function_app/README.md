# Function App Terraform Module

## 📘 Overview

This Terraform module creates an **Azure Function App** (Linux, Python 3.11) with enterprise security features including VNet integration, private endpoints for storage, managed identity, and Application Insights monitoring. Designed for serverless API backends with secure access to Azure PaaS services.

---

## ✅ Features

- **VNet Integration**: Outbound traffic routed through Virtual Network
- **Private Endpoints**: Storage (Blob + File) accessible only via VNet
- **Managed Identity**: System-assigned identity for passwordless authentication
- **Elastic Premium Plan**: Production-ready with VNET support (EP1 SKU)
- **HTTPS Only**: Enforced secure connections
- **Application Insights**: Built-in APM and monitoring
- **Storage Account**: Dedicated storage for function content
- **File Share**: Content delivery over VNet via WEBSITE_CONTENTOVERVNET
- **Health Checks**: Configurable endpoint monitoring
- **Custom App Settings**: Flexible configuration management

---

## ⚠️ Requirements

- **Terraform**: >= 1.5.0
- **Azure Provider**: ~> 4.0
- **VNet with Subnets**: VNet integration subnet and private endpoint subnet required
- **Application Insights**: For monitoring and diagnostics

---

## 📦 Resources Created

- `azurerm_storage_account`: Function App content storage
- `azurerm_storage_share`: File share for function content
- `azurerm_private_endpoint`: Storage Blob private endpoint
- `azurerm_private_endpoint`: Storage File private endpoint
- `azurerm_service_plan`: Elastic Premium (EP1) App Service Plan
- `azurerm_linux_function_app`: Linux Function App (Python 3.11)

---

## 🧩 Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `name` | Function App name | string | - | ✅ |
| `location` | Azure region | string | - | ✅ |
| `resource_group_name` | Resource group name | string | - | ✅ |
| `storage_account_name` | Storage account name (22 chars max) | string | - | ✅ |
| `vnet_integration_subnet_id` | Subnet ID for VNet integration | string | - | ✅ |
| `private_endpoint_subnet_id` | Subnet ID for private endpoints | string | - | ✅ |
| `app_insights_connection_string` | Application Insights connection string | string | - | ✅ |
| `runtime_version` | Python version (3.9, 3.10, 3.11) | string | `"3.11"` | ❌ |
| `health_check_path` | Health check endpoint path | string | `""` | ❌ |
| `app_settings` | Additional app settings | map(string) | `{}` | ❌ |
| `tags` | Resource tags | map(string) | `{}` | ❌ |

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `function_app_id` | Function App resource ID |
| `function_app_name` | Function App name |
| `function_app_default_hostname` | Default hostname (*.azurewebsites.net) |
| `function_app_principal_id` | Managed identity principal ID |
| `storage_account_id` | Storage account resource ID |
| `storage_account_name` | Storage account name |
| `app_service_plan_id` | App Service Plan resource ID |

---

## 🚀 Usage Example

```hcl
module "function_app" {
  source = "./modules/function_app"

  name                = "func-emp-api-dev"
  location            = "eastus2"
  resource_group_name = "rg-employee-app-dev"
  storage_account_name = "stfuncempdev123"
  
  # Networking
  vnet_integration_subnet_id = module.virtualsubnet.subnet_ids["function_app"]
  private_endpoint_subnet_id = module.virtualsubnet.subnet_ids["private_endpoints"]
  
  # Monitoring
  app_insights_connection_string = module.app_insights.connection_string
  
  # Runtime
  runtime_version  = "3.11"
  health_check_path = "/api/health"
  
  # Custom app settings
  app_settings = {
    "COSMOS_DB_ENDPOINT" = module.cosmos_db.cosmos_db_endpoint
    "KEY_VAULT_URL"      = module.key_vault.key_vault_uri
    "ENVIRONMENT"        = "dev"
  }
  
  tags = {
    Environment = "dev"
    Project     = "EmployeeManagement"
  }
}

# Grant Function App access to Cosmos DB (RBAC)
resource "azurerm_cosmosdb_sql_role_assignment" "function_app" {
  resource_group_name = "rg-employee-app-dev"
  account_name        = module.cosmos_db.cosmos_db_name
  role_definition_id  = "${module.cosmos_db.cosmos_db_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = module.function_app.function_app_principal_id
  scope               = module.cosmos_db.cosmos_db_id
}
```

---

## 📂 Module Structure

```
function_app/
├── main.tf       # Storage, App Service Plan, Function App, Private Endpoints
├── variables.tf  # Input variable definitions
├── outputs.tf    # Output value definitions
└── README.md     # This file
```

---

## 🔐 Security Features

✅ **VNet Integration**: Outbound traffic routed through VNet (WEBSITE_VNET_ROUTE_ALL=1)  
✅ **Private Endpoints**: Storage accessible only via private network  
✅ **Managed Identity**: System-assigned identity for RBAC  
✅ **HTTPS Only**: HTTP traffic redirected to HTTPS  
✅ **Public Access**: Enabled for deployment and Static Web App access (controlled by NSG)  
✅ **TLS 1.2**: Minimum TLS version enforced  
✅ **Content Over VNet**: Function content delivered via VNet (WEBSITE_CONTENTOVERVNET=1)

### Managed Identity Usage

```python
# In your Python Function App code
from azure.identity import DefaultAzureCredential
from azure.cosmos import CosmosClient

# Automatically uses managed identity when deployed
credential = DefaultAzureCredential()
client = CosmosClient(cosmos_endpoint, credential=credential)

# No connection strings or keys needed!
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Virtual Network                         │
│                                                             │
│  ┌─────────────────────┐      ┌─────────────────────┐     │
│  │ Function App Subnet │      │ Private Endpoints   │     │
│  │   (10.0.1.0/24)     │      │   (10.0.3.0/24)     │     │
│  │                     │      │                     │     │
│  │  ┌──────────────┐   │      │  ┌──────────────┐  │     │
│  │  │ Function App │───┼──────┼─▶│ Storage Blob │  │     │
│  │  │ (VNet Integ.)│   │      │  │      PE      │  │     │
│  │  └──────────────┘   │      │  └──────────────┘  │     │
│  │         │           │      │  ┌──────────────┐  │     │
│  │         └───────────┼──────┼─▶│ Storage File │  │     │
│  │                     │      │  │      PE      │  │     │
│  └─────────────────────┘      │  └──────────────┘  │     │
│                               │  ┌──────────────┐  │     │
│                               │  │  Cosmos DB   │  │     │
│                               │  │      PE      │  │     │
│                               │  └──────────────┘  │     │
│                               └─────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
         ▲                                       ▲
         │                                       │
         │                                  (RBAC + Private DNS)
         │
   Static Web App (HTTPS)
```

---

## 🧪 Testing

```bash
# Deploy module
terraform apply

# Verify Function App
az functionapp show \
  --name func-emp-api-dev \
  --resource-group rg-employee-app-dev

# Check VNet integration
az functionapp vnet-integration list \
  --name func-emp-api-dev \
  --resource-group rg-employee-app-dev

# View managed identity
az functionapp identity show \
  --name func-emp-api-dev \
  --resource-group rg-employee-app-dev

# Test function endpoint
curl https://func-emp-api-dev.azurewebsites.net/api/health

# View logs
az functionapp log tail \
  --name func-emp-api-dev \
  --resource-group rg-employee-app-dev
```

---

## 🔧 Advanced Configuration

### Custom Runtime Stack

```hcl
# For Node.js instead of Python
module "function_app" {
  source = "./modules/function_app"
  
  # ... other config ...
  
  # Modify main.tf to use node runtime
  site_config {
    application_stack {
      node_version = "18"  # Instead of python_version
    }
  }
}
```

### Always On (Production)

```hcl
# In main.tf, add to site_config:
site_config {
  always_on = true  # Keep function warm
  # ... other config
}
```

### Deployment Slots

```hcl
resource "azurerm_linux_function_app_slot" "staging" {
  name            = "staging"
  function_app_id = module.function_app.function_app_id
  
  site_config {
    # Mirror production config
  }
}
```

---

## 💰 Cost Optimization

| SKU | vCPU | RAM | Monthly Cost (approx.) | Use Case |
|-----|------|-----|------------------------|----------|
| Y1 (Consumption) | Shared | 1.5 GB | $0-$20 | Development only |
| EP1 (Elastic Premium) | 1 | 3.5 GB | $150-$170 | Production |
| EP2 (Elastic Premium) | 2 | 7 GB | $300-$340 | High load |

**This module uses EP1** (required for VNet integration)

**Cost Saving Tips**:
- Use Consumption Plan (Y1) for dev if VNet not needed
- Scale down instances during off-hours
- Monitor execution count and optimize cold starts

---

## 🐛 Troubleshooting

**Issue**: Function App cannot reach Cosmos DB  
**Solution**: Check VNet integration, private DNS zones, and NSG rules

```bash
# Test DNS resolution from function app
az functionapp config appsettings set \
  --name func-emp-api-dev \
  --resource-group rg-employee-app-dev \
  --settings "TEST_DNS=cosmos-emp-dev.documents.azure.com"
  
# Then run: nslookup from Kudu console
```

**Issue**: "Storage account not accessible" error  
**Solution**: Verify WEBSITE_CONTENTOVERVNET=1 and private endpoints exist

**Issue**: Function cold start timeout  
**Solution**: Enable Always On or use pre-warmed instances

**Issue**: Deployment fails  
**Solution**: Ensure public_network_access_enabled=true (required for deployment)

**Issue**: Managed identity authentication fails  
**Solution**: Verify RBAC role assignments:

```bash
az role assignment list --assignee <principal-id> --all
```

---

## 📊 Monitoring

### Key App Settings for Monitoring

```hcl
app_settings = {
  "APPLICATIONINSIGHTS_CONNECTION_STRING" = "<connection-string>"
  "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
  "APPINSIGHTS_INSTRUMENTATIONKEY" = "<instrumentation-key>"
}
```

### Metrics to Monitor

| Metric | Threshold | Action |
|--------|-----------|--------|
| Function Execution Count | Track baseline | Scale if increasing |
| Function Execution Time | > 5s | Optimize code |
| HTTP 5xx Errors | > 1% | Check logs |
| Memory Usage | > 80% | Scale up plan |
| CPU Usage | > 70% | Scale up instances |

---

## 📘 References

- [Azure Functions Documentation](https://learn.microsoft.com/en-us/azure/azure-functions/)
- [Terraform azurerm_linux_function_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app)
- [VNet Integration](https://learn.microsoft.com/en-us/azure/azure-functions/functions-networking-options)
- [Managed Identity](https://learn.microsoft.com/en-us/azure/app-service/overview-managed-identity)
- [Elastic Premium Plan](https://learn.microsoft.com/en-us/azure/azure-functions/functions-premium-plan)

---

## 👤 Maintainer

This module is part of the DTE Employee Management application infrastructure.  
Maintained by: DTE DevOps Team
