# Application Insights Terraform Module

## 📘 Overview

This Terraform module creates an **Azure Application Insights** resource for Application Performance Monitoring (APM), distributed tracing, and telemetry collection. Provides deep insights into application behavior, performance, and user interactions.

---

## ✅ Features

- **Workspace-Based**: Integrated with Log Analytics for unified querying
- **Distributed Tracing**: Track requests across microservices
- **Performance Monitoring**: Response times, dependencies, exceptions
- **Custom Telemetry**: Application-specific metrics and events
- **Live Metrics**: Real-time application monitoring
- **Smart Detection**: Automatic anomaly detection
- **Application Map**: Visual service dependencies

---

## ⚠️ Requirements

- **Terraform**: >= 1.5.0
- **Azure Provider**: ~> 4.0
- **Log Analytics Workspace**: Required for workspace-based mode

---

## 📦 Resources Created

- `azurerm_application_insights`: Application Insights instance

---

## 🧩 Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `name` | Application Insights name | string | - | ✅ |
| `location` | Azure region | string | - | ✅ |
| `resource_group_name` | Resource group name | string | - | ✅ |
| `log_analytics_workspace_id` | Log Analytics Workspace ID | string | - | ✅ |
| `application_type` | Application type (web, other, etc.) | string | `"web"` | ❌ |
| `retention_in_days` | Data retention period (30-730 days) | number | `30` | ❌ |
| `tags` | Resource tags | map(string) | `{}` | ❌ |

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `app_insights_id` | Application Insights resource ID |
| `instrumentation_key` | Instrumentation key (legacy, sensitive) |
| `connection_string` | Connection string (recommended, sensitive) |
| `app_id` | Application ID for queries |

---

## 🚀 Usage Example

```hcl
module "app_insights" {
  source = "./modules/app_insights"

  name                       = "appi-employee-app-dev"
  location                   = "eastus2"
  resource_group_name        = "rg-employee-app-dev"
  log_analytics_workspace_id = module.log_analytics.workspace_id
  
  application_type   = "web"
  retention_in_days  = 30  # 30 days for dev, 90+ for prod
  
  tags = {
    Environment = "dev"
    Project     = "EmployeeManagement"
  }
}

# Use in Function App
module "function_app" {
  source = "./modules/function_app"
  
  # ... other config ...
  app_insights_connection_string = module.app_insights.connection_string
}

# Use in Static Web App (via app settings)
resource "azurerm_static_web_app" "example" {
  # ... config ...
  
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = module.app_insights.instrumentation_key
  }
}
```

---

## 📂 Module Structure

```
app_insights/
├── main.tf       # Application Insights resource
├── variables.tf  # Input variable definitions
├── outputs.tf    # Output value definitions
└── README.md     # This file
```

---

## 📊 Telemetry Types

### Automatic Telemetry (No Code Changes)

- **Requests**: HTTP request count, duration, status codes
- **Dependencies**: External API calls, database queries
- **Exceptions**: Unhandled errors and stack traces
- **Performance Counters**: CPU, memory, disk I/O
- **Availability**: Endpoint health checks

### Custom Telemetry (Code Integration)

**Python (Function App)**:
```python
from opencensus.ext.azure.log_exporter import AzureLogHandler
import logging

# Configure Application Insights
logger = logging.getLogger(__name__)
logger.addHandler(AzureLogHandler(
    connection_string='<connection-string-from-terraform>'
))

# Log custom events
logger.info('Employee created', extra={'custom_dimensions': {'employee_id': 123}})

# Track custom metrics
from opencensus.ext.azure import metrics_exporter
exporter = metrics_exporter.new_metrics_exporter(
    connection_string='<connection-string>'
)
```

**JavaScript (Frontend)**:
```javascript
import { ApplicationInsights } from '@microsoft/applicationinsights-web';

const appInsights = new ApplicationInsights({
  config: {
    connectionString: process.env.REACT_APP_APPINSIGHTS_CONNECTION_STRING
  }
});
appInsights.loadAppInsights();
appInsights.trackPageView();

// Track custom events
appInsights.trackEvent({ name: 'EmployeeCreated', properties: { id: 123 } });

// Track metrics
appInsights.trackMetric({ name: 'EmployeeCount', average: 50 });
```

---

## 📈 Monitoring Dashboards

### Performance Dashboard (KQL Queries)

**Average Response Time**:
```kusto
requests
| where timestamp > ago(1h)
| summarize avg(duration) by bin(timestamp, 5m)
| render timechart
```

**Failure Rate**:
```kusto
requests
| where timestamp > ago(24h)
| summarize Total = count(), Failed = countif(success == false) by bin(timestamp, 1h)
| extend FailureRate = (Failed * 100.0) / Total
| render timechart
```

**Top Slowest Requests**:
```kusto
requests
| where timestamp > ago(1h)
| top 10 by duration desc
| project timestamp, name, duration, resultCode, url
```

**Dependency Performance**:
```kusto
dependencies
| where timestamp > ago(1h)
| summarize avg(duration), count() by name, type
| order by avg_duration desc
```

---

## 🔔 Smart Detection Alerts

Application Insights automatically detects:

- **Performance Anomalies**: Slow response times
- **Failure Anomalies**: Unusual error rates
- **Memory Leaks**: Increasing memory usage
- **Trace Severity Anomalies**: Unusual log patterns
- **Exception Volume**: Spike in exceptions

Configure action groups to receive alerts:

```hcl
resource "azurerm_monitor_action_group" "app_insights_alerts" {
  name                = "ag-app-insights-alerts"
  resource_group_name = "rg-employee-app-dev"
  short_name          = "appinsight"

  email_receiver {
    name          = "DevOpsTeam"
    email_address = "devops@company.com"
  }
  
  sms_receiver {
    name         = "OnCall"
    country_code = "1"
    phone_number = "5551234567"
  }
}
```

---

## 💰 Cost Optimization

### Pricing Tiers

| Data Volume | Monthly Cost (approx.) |
|-------------|------------------------|
| 0-5 GB | Free |
| 5-10 GB | $5-10 |
| 50 GB | ~$115 |
| 100 GB | ~$230 |

**First 5 GB/month is free!**

### Cost Saving Tips

**Sampling** (reduces telemetry volume):
```python
# In Function App configuration
from opencensus.trace.samplers import ProbabilitySampler

# 20% sampling (captures 1 in 5 requests)
tracer = Tracer(sampler=ProbabilitySampler(rate=0.2))
```

**Filter Unnecessary Data**:
```javascript
// In frontend
appInsights.addTelemetryInitializer((envelope) => {
  // Don't track health check endpoints
  if (envelope.baseData.url.includes('/health')) {
    return false;
  }
  return true;
});
```

**Adjust Retention**:
```hcl
# Dev: 30 days
retention_in_days = 30

# Prod: 90 days (balance cost vs compliance)
retention_in_days = 90
```

---

## 🧪 Testing

```bash
# Deploy module
terraform apply

# Get connection string
terraform output -raw app_insights_connection_string

# View in Azure Portal
az monitor app-insights component show \
  --app appi-employee-app-dev \
  --resource-group rg-employee-app-dev

# Query telemetry
az monitor app-insights metrics show \
  --app appi-employee-app-dev \
  --resource-group rg-employee-app-dev \
  --metric requests/count

# Live metrics (real-time)
# Navigate to: Azure Portal > Application Insights > Live Metrics
```

---

## 🔧 Advanced Features

### Availability Tests

```hcl
resource "azurerm_application_insights_web_test" "availability" {
  name                    = "test-homepage"
  location                = "eastus2"
  resource_group_name     = "rg-employee-app-dev"
  application_insights_id = module.app_insights.app_insights_id
  kind                    = "ping"
  frequency               = 300  # 5 minutes
  timeout                 = 30
  enabled                 = true
  
  geo_locations = [
    "us-va-ash-azr",  # East US
    "us-ca-sjc-azr"   # West US
  ]
  
  configuration = <<XML
<WebTest Name="Homepage" Id="ABD48585-0831-40CB-9069-682EA6BB3583" Enabled="True" Timeout="30" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010">
  <Items>
    <Request Method="GET" Version="1.1" Url="https://white-sky-0a425c40f.6.azurestaticapps.net/" ThinkTime="0" Timeout="30" />
  </Items>
</WebTest>
XML
}
```

### Multi-Step Web Tests

Monitor complex user journeys with Application Insights Standard tests (requires Standard pricing tier).

---

## 🐛 Troubleshooting

**Issue**: No telemetry data appearing  
**Solution**: Verify connection string is configured in application, check firewall rules

**Issue**: High costs  
**Solution**: Enable sampling, reduce retention, filter unnecessary events

**Issue**: Missing dependency data  
**Solution**: Ensure dependency tracking is enabled in SDK configuration

**Issue**: Instrumentation key vs Connection String  
**Solution**: Use connection string (modern approach), instrumentation key is legacy

---

## 📘 References

- [Application Insights Documentation](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Terraform azurerm_application_insights](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights)
- [Application Insights for Python](https://learn.microsoft.com/en-us/azure/azure-monitor/app/opencensus-python)
- [Application Insights JavaScript SDK](https://learn.microsoft.com/en-us/azure/azure-monitor/app/javascript)
- [KQL for Application Insights](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/)

---

## 👤 Maintainer

This module is part of the DTE Employee Management application infrastructure.  
Maintained by: DTE DevOps Team
