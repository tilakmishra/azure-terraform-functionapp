# Network Security Group Terraform Module

## 📘 Overview

This Terraform module creates **Azure Network Security Groups (NSGs)** with predefined security rules for different subnet types. It provides network-level firewall protection with rules optimized for Function App, Private Endpoints, and Data subnets.

---

## ✅ Features

- **Dynamic NSG Creation**: Creates one NSG per subnet configuration
- **Pre-configured Rules**: Security rules for common Azure services
- **Subnet Association**: Automatic NSG to subnet binding
- **Defense in Depth**: Network layer protection for zero-trust architecture
- **Customizable Rules**: Supports additional custom security rules
- **Tagging Support**: Consistent resource tagging

---

## ⚠️ Requirements

- **Terraform**: >= 1.5.0
- **Azure Provider**: ~> 4.0
- **Existing Subnets**: Subnets must be created before NSG association

---

## 📦 Resources Created

- `azurerm_network_security_group`: One NSG per subnet
- `azurerm_network_security_rule`: Security rules (inbound/outbound)
- `azurerm_subnet_network_security_group_association`: NSG to subnet bindings

---

## 🧩 Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `resource_group_name` | Name of the resource group | string | - | ✅ |
| `environment` | Environment name (dev/stg/prod) | string | - | ✅ |
| `subnet_configs` | Map of subnet configurations | map(object) | - | ✅ |
| `subnet_ids` | Map of subnet IDs for association | map(string) | `{}` | ❌ |
| `tags` | Tags to apply to NSGs | map(string) | `{}` | ❌ |

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `nsg_ids` | Map of NSG names to their Azure resource IDs |
| `nsg_names` | Map of subnet keys to NSG names |

---

## 🚀 Usage Example

```hcl
module "securitygroup" {
  source = "./modules/securitygroup"

  resource_group_name = "rg-employee-app-dev"
  environment         = "dev"
  
  subnet_configs = {
    function_app = {
      address_prefixes = ["10.0.1.0/24"]
    }
    private_endpoints = {
      address_prefixes = ["10.0.3.0/24"]
    }
    data = {
      address_prefixes = ["10.0.4.0/24"]
    }
  }
  
  subnet_ids = {
    function_app      = module.virtualsubnet.subnet_ids["function_app"]
    private_endpoints = module.virtualsubnet.subnet_ids["private_endpoints"]
    data              = module.virtualsubnet.subnet_ids["data"]
  }
  
  tags = {
    Environment = "dev"
    Project     = "EmployeeManagement"
  }
}
```

---

## 🔒 Security Rules Implemented

### Function App Subnet Rules

| Rule | Direction | Priority | Source | Dest Port | Protocol | Action | Purpose |
|------|-----------|----------|--------|-----------|----------|--------|---------|
| allow-https-inbound-from-swa | Inbound | 100 | AppService | 443 | TCP | Allow | Static Web App → Function App |
| allow-https-outbound | Outbound | 100 | VirtualNetwork | 443 | TCP | Allow | HTTPS to Azure services |
| allow-dns-outbound | Outbound | 110 | VirtualNetwork | 53 | UDP | Allow | DNS resolution |
| allow-cosmosdb-outbound | Outbound | 120 | VirtualNetwork | 443 | TCP | Allow | Cosmos DB access |
| deny-all-inbound | Inbound | 4096 | * | * | * | Deny | Default deny |

### Private Endpoints Subnet Rules

| Rule | Direction | Priority | Action | Purpose |
|------|-----------|----------|--------|---------|
| allow-vnet-inbound | Inbound | 100 | Allow | VNet traffic to private endpoints |
| allow-vnet-outbound | Outbound | 100 | Allow | Private endpoint responses |
| deny-all-inbound | Inbound | 4096 | Deny | Default deny |

### Data Subnet Rules

| Rule | Direction | Priority | Action | Purpose |
|------|-----------|----------|--------|---------|
| allow-vnet-inbound | Inbound | 100 | Allow | VNet services → Data subnet |
| allow-vnet-outbound | Outbound | 100 | Allow | Data subnet → VNet |
| deny-internet-outbound | Outbound | 4000 | Deny | Block internet access |
| deny-all-inbound | Inbound | 4096 | Deny | Default deny |

---

## 📂 Module Structure

```
securitygroup/
├── main.tf       # NSG and security rule definitions
├── variables.tf  # Input variable definitions
├── outputs.tf    # Output value definitions
└── README.md     # This file
```

---

## 🔐 Best Practices

✅ **Least Privilege**: Only allow required traffic, deny everything else  
✅ **Priority Planning**: Use ranges (100-199 for allows, 4000-4096 for denies)  
✅ **Service Tags**: Use Azure service tags instead of IP addresses when possible  
✅ **Logging**: Enable NSG flow logs for security monitoring  
✅ **Regular Review**: Audit rules quarterly to remove unnecessary permissions  
✅ **Naming Convention**: Use descriptive rule names like `allow-https-inbound-from-swa`

### Common Azure Service Tags

| Service Tag | Description | Use Case |
|-------------|-------------|----------|
| `AppService` | Azure App Service | Static Web App, Function App |
| `AzureCosmosDB` | Cosmos DB | Database access |
| `Storage` | Azure Storage | Blob, File, Queue, Table |
| `KeyVault` | Azure Key Vault | Secrets access |
| `AzureMonitor` | Azure Monitor | Logging/metrics |
| `VirtualNetwork` | Current VNet | Intra-VNet communication |
| `Internet` | Public internet | External access |

---

## 🧪 Testing

```bash
# Navigate to module directory
cd modules/securitygroup

# Initialize
terraform init

# Validate
terraform validate

# Plan
terraform plan

# Apply
terraform apply

# Verify NSGs
az network nsg list --resource-group rg-employee-app-dev

# View NSG rules
az network nsg rule list \
  --nsg-name nsg-function-app-dev \
  --resource-group rg-employee-app-dev \
  --output table
```

---

## 🔧 Advanced Configuration

### Custom Security Rules

To add custom rules, modify the module or extend it:

```hcl
# After module deployment, add custom rules
resource "azurerm_network_security_rule" "custom_rule" {
  name                        = "allow-bastion-inbound"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "10.0.20.0/24"  # Bastion subnet
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = "rg-employee-app-dev"
  network_security_group_name = module.securitygroup.nsg_names["function_app"]
}
```

### NSG Flow Logs (Recommended)

```hcl
resource "azurerm_network_watcher_flow_log" "nsg_flow_log" {
  network_watcher_name = "NetworkWatcher_eastus2"
  resource_group_name  = "NetworkWatcherRG"
  
  network_security_group_id = module.securitygroup.nsg_ids["function_app"]
  storage_account_id        = azurerm_storage_account.logs.id
  enabled                   = true
  
  retention_policy {
    enabled = true
    days    = 30
  }
  
  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.main.workspace_id
    workspace_region      = "eastus2"
    workspace_resource_id = azurerm_log_analytics_workspace.main.id
  }
}
```

---

## 🐛 Troubleshooting

**Issue**: Function App cannot reach Cosmos DB  
**Solution**: Verify `allow-cosmosdb-outbound` rule exists and priority doesn't conflict with deny rules

**Issue**: Static Web App gets 403 error calling Function App  
**Solution**: Check `allow-https-inbound-from-swa` rule allows traffic from AppService tag

**Issue**: DNS resolution failing  
**Solution**: Ensure `allow-dns-outbound` rule permits UDP 53 traffic

**Issue**: Private endpoint connections timing out  
**Solution**: Verify `allow-vnet-inbound` rule on private_endpoints NSG

**Debugging NSG Issues**:

```bash
# Check effective security rules on a network interface
az network nic list-effective-nsg \
  --name <nic-name> \
  --resource-group <rg-name>

# View NSG flow logs
# (Requires flow logs to be enabled)
az network watcher flow-log show \
  --location eastus2 \
  --name <flow-log-name>
```

---

## 🔍 Security Considerations

⚠️ **Avoid Overly Permissive Rules**: Never use `*` for both source and destination  
⚠️ **Internet Access**: Block internet outbound by default, allow only when necessary  
⚠️ **Management Ports**: Never expose RDP (3389) or SSH (22) to internet  
⚠️ **Logging**: Enable NSG flow logs for compliance and incident response  
⚠️ **Regular Audits**: Review NSG rules every quarter  
⚠️ **Testing**: Always test connectivity after NSG changes

---

## 📘 References

- [Azure Network Security Groups](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [Terraform azurerm_network_security_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group)
- [Azure Service Tags](https://learn.microsoft.com/en-us/azure/virtual-network/service-tags-overview)
- [NSG Flow Logs](https://learn.microsoft.com/en-us/azure/network-watcher/network-watcher-nsg-flow-logging-overview)

---

## 👤 Maintainer

This module is part of the DTE Employee Management application infrastructure.  
Maintained by: DTE DevOps Team
