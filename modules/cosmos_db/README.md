# Cosmos DB Terraform Module

## 📘 Overview

This Terraform module creates an **Azure Cosmos DB account** with SQL API, configured for enterprise security with VNet integration, private endpoints, and private DNS zone support. Perfect for production workloads requiring secure, scalable NoSQL database capabilities.

---

## ✅ Features

- **Private Endpoint Support**: Secure access via private network connectivity
- **Private DNS Zone Integration**: Automatic DNS resolution for private endpoints
- **VNet Service Endpoints**: Direct access from specific subnets
- **Public Access Disabled**: Zero-trust security by default
- **Session Consistency**: Balanced consistency for web applications
- **Diagnostic Settings**: Integration with Log Analytics
- **Flexible Throughput**: Configurable RU/s provisioning
- **Container Auto-creation**: Database and container included

---

## ⚠️ Requirements

- **Terraform**: >= 1.5.0
- **Azure Provider**: ~> 4.0
- **VNet with Subnets**: Private endpoint subnet and allowed subnets must exist
- **Private DNS Zone**: Required for private endpoint hostname resolution

---

## 📦 Resources Created

- `azurerm_cosmosdb_account`: Cosmos DB account with VNet filtering
- `azurerm_cosmosdb_sql_database`: SQL API database
- `azurerm_cosmosdb_sql_container`: Container with partition key
- `azurerm_private_endpoint`: Private endpoint for secure access
- `azurerm_monitor_diagnostic_setting`: Diagnostic logs (optional)

---

## 🧩 Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `name` | Cosmos DB account name (globally unique) | string | - | ✅ |
| `location` | Azure region | string | - | ✅ |
| `resource_group_name` | Resource group name | string | - | ✅ |
| `database_name` | SQL database name | string | - | ✅ |
| `container_name` | Container name | string | - | ✅ |
| `partition_key_path` | Partition key (e.g., "/id") | string | - | ✅ |
| `throughput` | Provisioned RU/s (min 400) | number | `400` | ❌ |
| `allowed_subnet_ids` | Subnet IDs for service endpoint access | list(string) | `[]` | ❌ |
| `private_endpoint_subnet_id` | Subnet ID for private endpoint | string | - | ✅ |
| `private_dns_zone_id` | Private DNS zone ID for DNS resolution | string | `null` | ❌ |
| `enable_diagnostics` | Enable diagnostic settings | bool | `false` | ❌ |
| `log_analytics_workspace_id` | Log Analytics workspace ID | string | `null` | ❌ |
| `tags` | Resource tags | map(string) | `{}` | ❌ |

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `cosmos_db_id` | Cosmos DB account resource ID |
| `cosmos_db_endpoint` | Cosmos DB endpoint URL |
| `cosmos_db_name` | Cosmos DB account name |
| `database_name` | SQL database name |
| `container_name` | Container name |
| `private_endpoint_id` | Private endpoint resource ID |
| `private_ip_address` | Private endpoint IP address |

---

## 🚀 Usage Example

```hcl
# Create Private DNS Zone first
module "cosmos_private_dns_zone" {
  source = "./modules/private_dns_zone"

  zone_name           = "privatelink.documents.azure.com"
  resource_group_name = "rg-employee-app-dev"
  virtual_network_id  = module.virtualnetwork.virtual_network_id
  
  tags = var.tags
}

# Deploy Cosmos DB with private endpoint
module "cosmos_db" {
  source = "./modules/cosmos_db"

  name                = "cosmos-emp-dev-abc123"
  location            = "eastus2"
  resource_group_name = "rg-employee-app-dev"
  
  # Database configuration
  database_name      = "EmployeeDB"
  container_name     = "Employees"
  partition_key_path = "/id"
  throughput         = 400
  
  # Networking - Private endpoint
  private_endpoint_subnet_id = module.virtualsubnet.subnet_ids["private_endpoints"]
  private_dns_zone_id        = module.cosmos_private_dns_zone.private_dns_zone_id
  
  # Networking - Service endpoints for additional subnets
  allowed_subnet_ids = [
    module.virtualsubnet.subnet_ids["function_app"],
    module.virtualsubnet.subnet_ids["data"]
  ]
  
  # Monitoring
  enable_diagnostics         = true
  log_analytics_workspace_id = module.log_analytics.workspace_id
  
  tags = {
    Environment = "dev"
    Project     = "EmployeeManagement"
  }
}

# Access from Function App (uses managed identity + RBAC)
# See rbac.tf for role assignment configuration
```

---

## 📂 Module Structure

```
cosmos_db/
├── main.tf       # Cosmos DB resources and private endpoint
├── variables.tf  # Input variable definitions
├── outputs.tf    # Output value definitions
└── README.md     # This file
```

---

## 🔐 Security Features

✅ **Public Access Disabled**: `public_network_access_enabled = false`  
✅ **Private Endpoint**: All traffic routed through VNet  
✅ **Private DNS Zone**: Hostname resolves to private IP (10.0.x.x)  
✅ **VNet Filtering**: Service endpoints restrict access to specific subnets  
✅ **RBAC Authentication**: No connection strings, managed identity only  
✅ **Soft Delete**: Built-in (cannot be disabled on Cosmos DB)  
✅ **Encryption at Rest**: Azure-managed keys by default

### Authentication Flow

```
Function App (Managed Identity)
    ↓
Private DNS Resolution (privatelink.documents.azure.com → 10.0.3.x)
    ↓
Private Endpoint (10.0.3.0/24 subnet)
    ↓
Cosmos DB Account (RBAC: Cosmos DB Built-in Data Contributor)
    ↓
Database & Container Access
```

---

## 🧪 Testing

```bash
# Deploy module
terraform apply

# Verify Cosmos DB creation
az cosmosdb show \
  --name cosmos-emp-dev-abc123 \
  --resource-group rg-employee-app-dev

# Check private endpoint
az network private-endpoint show \
  --name pe-cosmos-emp-dev-abc123 \
  --resource-group rg-employee-app-dev

# Verify DNS resolution (from within VNet)
nslookup cosmos-emp-dev-abc123.documents.azure.com
# Should resolve to 10.0.3.x (private IP)

# Test RBAC access (requires role assignment)
az cosmosdb sql role assignment list \
  --account-name cosmos-emp-dev-abc123 \
  --resource-group rg-employee-app-dev
```

---

## 🔧 Advanced Configuration

### Autoscale Throughput

```hcl
# Note: Current module uses manual throughput
# To enable autoscale, modify main.tf:

resource "azurerm_cosmosdb_sql_database" "database" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  
  autoscale_settings {
    max_throughput = 4000  # Auto-scales from 400 to 4000 RU/s
  }
}
```

### Multi-Region Deployment

```hcl
# In main.tf, add additional geo_location blocks:

resource "azurerm_cosmosdb_account" "main" {
  # ... existing config ...
  
  geo_location {
    location          = var.location
    failover_priority = 0
  }
  
  geo_location {
    location          = "westus2"
    failover_priority = 1
  }
}
```

### Custom Indexing Policy

```hcl
resource "azurerm_cosmosdb_sql_container" "container" {
  # ... existing config ...
  
  indexing_policy {
    indexing_mode = "consistent"
    
    # Include specific paths
    included_path {
      path = "/name/*"
    }
    included_path {
      path = "/department/*"
    }
    
    # Exclude large fields
    excluded_path {
      path = "/description/*"
    }
  }
}
```

---

## 💰 Cost Optimization

| Configuration | RU/s | Monthly Cost (approx.) | Use Case |
|---------------|------|------------------------|----------|
| Development | 400 | $24 | Dev/test environments |
| Staging | 1,000 | $60 | Pre-production testing |
| Production | 4,000 | $240 | Production workloads |
| Autoscale (400-4000) | Variable | $24-$240 | Variable workloads |

**Cost Saving Tips**:
- Use autoscale for variable workloads
- Set lower throughput in dev environments
- Use serverless tier for infrequent access (not in this module)
- Monitor RU consumption with App Insights

---

## 🐛 Troubleshooting

**Issue**: Function App cannot connect to Cosmos DB  
**Solution**: Verify Private DNS zone is linked to VNet and private endpoint has DNS zone group configured

```bash
# Check DNS zone link
az network private-dns link vnet list \
  --resource-group rg-employee-app-dev \
  --zone-name privatelink.documents.azure.com
```

**Issue**: "Public access is disabled" error  
**Solution**: Ensure connections come through private endpoint or allowed subnets

**Issue**: RBAC authentication fails  
**Solution**: Verify role assignment exists:

```bash
az cosmosdb sql role assignment list \
  --account-name <cosmos-name> \
  --resource-group <rg-name>
```

**Issue**: High RU consumption  
**Solution**: Enable diagnostic settings and monitor metrics:

```bash
az monitor metrics list \
  --resource <cosmos-db-id> \
  --metric TotalRequests
```

---

## 📊 Monitoring

### Key Metrics to Monitor

| Metric | Threshold | Action |
|--------|-----------|--------|
| Total Request Units | > 80% of provisioned | Scale up RU/s |
| Throttled Requests | > 1% | Increase throughput |
| Availability | < 99.9% | Check health status |
| Server-side Latency | > 10ms | Optimize queries |
| Replication Latency | > 1s | Check multi-region config |

### Diagnostic Logs

```hcl
# Enable in module
enable_diagnostics         = true
log_analytics_workspace_id = module.log_analytics.workspace_id
```

**Log Categories**:
- `DataPlaneRequests`: All data operations
- `QueryRuntimeStatistics`: Query performance
- `PartitionKeyStatistics`: Partition usage
- `ControlPlaneRequests`: Management operations

---

## 📘 References

- [Azure Cosmos DB Documentation](https://learn.microsoft.com/en-us/azure/cosmos-db/)
- [Terraform azurerm_cosmosdb_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_account)
- [Cosmos DB Private Endpoints](https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-configure-private-endpoints)
- [Cosmos DB RBAC](https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-setup-rbac)
- [Request Units (RU/s)](https://learn.microsoft.com/en-us/azure/cosmos-db/request-units)

---

## 👤 Maintainer

This module is part of the DTE Employee Management application infrastructure.  
Maintained by: DTE DevOps Team
