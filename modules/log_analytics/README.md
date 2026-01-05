# Log Analytics Workspace Terraform Module

## 📘 Overview

This Terraform module creates an **Azure Log Analytics Workspace** for centralized logging, monitoring, and analytics. Serves as the foundation for Application Insights, diagnostic settings, and security monitoring across your Azure infrastructure.

---

## ✅ Features

- **Centralized Logging**: Single location for all logs and metrics
- **Query with KQL**: Powerful Kusto Query Language for analysis
- **Integration with App Insights**: Workspace-based Application Insights
- **Diagnostic Settings**: Receive logs from all Azure resources
- **Retention Control**: Configurable log retention period
- **Cost-Effective**: Pay-as-you-go PerGB2018 pricing tier

---

## ⚠️ Requirements

- **Terraform**: >= 1.5.0
- **Azure Provider**: ~> 4.0

---

## 📦 Resources Created

- `azurerm_log_analytics_workspace`: Log Analytics Workspace

---

## 🧩 Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `name` | Log Analytics Workspace name | string | - | ✅ |
| `location` | Azure region | string | - | ✅ |
| `resource_group_name` | Resource group name | string | - | ✅ |
| `retention_in_days` | Log retention period (30-730 days) | number | `30` | ❌ |
| `tags` | Resource tags | map(string) | `{}` | ❌ |

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `workspace_id` | Log Analytics Workspace resource ID |
| `workspace_name` | Workspace name |
| `workspace_id_for_insights` | Workspace ID (used by App Insights) |
| `primary_shared_key` | Primary key for agent authentication (sensitive) |

---

## 🚀 Usage Example

```hcl
module "log_analytics" {
  source = "./modules/log_analytics"

  name                = "log-employee-app-dev"
  location            = "eastus2"
  resource_group_name = "rg-employee-app-dev"
  retention_in_days   = 30  # 30 days for dev, 90+ for prod
  
  tags = {
    Environment = "dev"
    Project     = "EmployeeManagement"
  }
}

# Use in Application Insights
module "app_insights" {
  source = "./modules/app_insights"
  
  # ... other config ...
  log_analytics_workspace_id = module.log_analytics.workspace_id
}

# Use in diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "cosmos_db" {
  name                       = "diag-cosmos"
  target_resource_id         = azurerm_cosmosdb_account.main.id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  
  enabled_log {
    category = "DataPlaneRequests"
  }
  
  metric {
    category = "Requests"
  }
}
```

---

## 📂 Module Structure

```
log_analytics/
├── main.tf       # Log Analytics Workspace resource
├── variables.tf  # Input variable definitions
├── outputs.tf    # Output value definitions
└── README.md     # This file
```

---

## 📊 Querying Logs with KQL

Access logs via Azure Portal > Log Analytics Workspaces > Logs

### Example Queries

**Function App Errors**:
```kusto
FunctionAppLogs
| where TimeGenerated > ago(1h)
| where Level == "Error"
| project TimeGenerated, Message, FunctionName
| order by TimeGenerated desc
```

**Cosmos DB Slow Queries**:
```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.DOCUMENTDB"
| where Category == "DataPlaneRequests"
| where toint(duration_s) > 1000  // > 1 second
| project TimeGenerated, OperationName, duration_s, requestCharge_s
| order by duration_s desc
```

**HTTP Requests by Status Code**:
```kusto
AppRequests
| summarize count() by ResultCode, bin(TimeGenerated, 1h)
| render timechart
```

**Failed Authentication Attempts**:
```kusto
SigninLogs
| where ResultType != "0"
| summarize count() by UserPrincipalName, ResultDescription
| order by count_ desc
```

---

## 💰 Cost Optimization

### Pricing Tiers

| Tier | Price | Best For |
|------|-------|----------|
| **PerGB2018** | $2.30/GB | Most scenarios |
| **100GB/day** | $196/month | High volume (>85GB/day) |
| **200GB/day** | $374/month | Enterprise |

**This module uses PerGB2018** (default, most flexible)

### Data Retention Costs

- **First 31 days**: Included (free)
- **Days 32-730**: $0.10/GB/month

### Cost Saving Tips

```hcl
# Development: 30-day retention
retention_in_days = 30

# Staging: 60-day retention
retention_in_days = 60

# Production: 90-180 day retention (compliance)
retention_in_days = 90
```

**Filter unnecessary logs**:
```hcl
resource "azurerm_monitor_diagnostic_setting" "example" {
  # ... other config ...
  
  # Only enable critical log categories
  enabled_log {
    category = "Errors"
  }
  
  # Skip verbose categories like "Allmetrics" unless needed
}
```

**Monthly cost estimate**:
- Dev (5 GB/month): ~$12
- Prod (50 GB/month): ~$115

---

## 🔧 Advanced Configuration

### Data Collection Rules

```hcl
resource "azurerm_monitor_data_collection_rule" "example" {
  name                = "dcr-employee-app"
  resource_group_name = "rg-employee-app-dev"
  location            = "eastus2"
  
  destinations {
    log_analytics {
      workspace_resource_id = module.log_analytics.workspace_id
      name                  = "destination-log"
    }
  }
  
  data_flow {
    streams      = ["Microsoft-Event"]
    destinations = ["destination-log"]
  }
}
```

### Alerts Based on Logs

```hcl
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "high_error_rate" {
  name                = "alert-high-error-rate"
  resource_group_name = "rg-employee-app-dev"
  location            = "eastus2"
  
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes               = [module.log_analytics.workspace_id]
  severity             = 2
  
  criteria {
    query = <<-QUERY
      FunctionAppLogs
      | where Level == "Error"
      | summarize count() by bin(TimeGenerated, 5m)
      | where count_ > 10
    QUERY
    
    time_aggregation_method = "Count"
    threshold               = 10
    operator                = "GreaterThan"
  }
  
  action {
    action_groups = [azurerm_monitor_action_group.alerts.id]
  }
}
```

---

## 🧪 Testing

```bash
# Deploy module
terraform apply

# Verify workspace
az monitor log-analytics workspace show \
  --name log-employee-app-dev \
  --resource-group rg-employee-app-dev

# Run a test query
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "Heartbeat | take 10"

# Check data ingestion
az monitor log-analytics workspace get-schema \
  --workspace-name log-employee-app-dev \
  --resource-group rg-employee-app-dev
```

---

## 📊 Common Log Tables

| Table Name | Description |
|------------|-------------|
| `AppRequests` | HTTP requests to applications |
| `AppExceptions` | Application exceptions |
| `AppTraces` | Application trace logs |
| `AzureDiagnostics` | Azure resource diagnostic logs |
| `FunctionAppLogs` | Function App execution logs |
| `AzureActivity` | Azure control plane operations |
| `SecurityEvent` | Windows security events |
| `Syslog` | Linux syslog messages |
| `ContainerLog` | Container stdout/stderr |

---

## 🔒 Security Considerations

✅ **Access Control**: Use RBAC to restrict log access  
✅ **Data Encryption**: Logs encrypted at rest automatically  
✅ **Network Security**: Can configure Private Link (not in this module)  
⚠️ **Sensitive Data**: Avoid logging secrets, passwords, or PII

### RBAC Roles for Logs

| Role | Permissions | Use Case |
|------|-------------|----------|
| `Log Analytics Reader` | Read logs | Developers |
| `Log Analytics Contributor` | Read + Modify | DevOps team |
| `Monitoring Reader` | Read metrics + logs | Security team |

---

## 🐛 Troubleshooting

**Issue**: No logs appearing  
**Solution**: Verify diagnostic settings are configured and retention period hasn't expired

**Issue**: Query returns no results  
**Solution**: Check time range, table name (case-sensitive), and data ingestion delay (up to 5 min)

**Issue**: High costs  
**Solution**: Review ingestion volume, reduce retention, or filter diagnostic logs

```bash
# Check ingestion volume
az monitor log-analytics workspace table show \
  --workspace-name log-employee-app-dev \
  --resource-group rg-employee-app-dev \
  --name AzureDiagnostics
```

---

## 📘 References

- [Log Analytics Documentation](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-overview)
- [Terraform azurerm_log_analytics_workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace)
- [KQL Quick Reference](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/)
- [Log Analytics Pricing](https://azure.microsoft.com/en-us/pricing/details/monitor/)

---

## 👤 Maintainer

This module is part of the DTE Employee Management application infrastructure.  
Maintained by: DTE DevOps Team
