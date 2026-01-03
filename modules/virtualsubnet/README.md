# Virtual Subnet Terraform Module

## 📘 Overview

This Terraform module creates **Azure Subnets** within an existing Virtual Network with support for service endpoints, delegations, and Network Security Group associations. It enables dynamic subnet creation based on configuration maps, perfect for creating multiple subnets with different purposes.

---

## ✅ Features

- **Dynamic Subnet Creation**: Create multiple subnets from a single configuration
- **Service Endpoints**: Enable direct access to Azure PaaS services
- **Subnet Delegation**: Support for App Service VNet integration
- **NSG Association**: Automatic NSG attachment per subnet
- **Private Endpoint Support**: Network policies disabled for private endpoints
- **Flexible Configuration**: Map-based configuration for easy management

---

## ⚠️ Requirements

- **Terraform**: >= 1.5.0
- **Azure Provider**: ~> 4.0
- **Existing VNet**: Virtual Network must exist
- **Resource Group**: Must exist before subnet creation

---

## 📦 Resources Created

- `azurerm_subnet`: One or more subnets within the VNet
- `azurerm_subnet_network_security_group_association`: NSG associations per subnet

---

## 🧩 Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `vnet_name` | Name of the Virtual Network | string | - | ✅ |
| `resource_group_name` | Resource group containing the VNet | string | - | ✅ |
| `environment` | Environment name (dev/stg/prod) | string | - | ✅ |
| `subnet_configs` | Map of subnet configurations | map(object) | - | ✅ |
| `nsg_ids` | Map of NSG IDs to associate with subnets | map(string) | `{}` | ❌ |

### Subnet Configuration Object Schema

```hcl
subnet_configs = {
  "<subnet_key>" = {
    address_prefixes  = ["10.0.X.0/24"]        # Required
    service_endpoints = ["Microsoft.Sql", ...] # Optional
    delegation = {                             # Optional
      name         = "delegation-name"
      service_name = "Microsoft.Web/serverFarms"
      actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}
```

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `subnet_ids` | Map of subnet names to their Azure resource IDs |
| `subnet_names` | Map of subnet keys to subnet names |
| `subnet_address_prefixes` | Map of subnet address ranges |

---

## 🚀 Usage Example

### Basic Subnet Configuration

```hcl
module "virtualsubnet" {
  source = "./modules/virtualsubnet"

  vnet_name           = "vnet-employee-app-dev"
  resource_group_name = "rg-employee-app-dev"
  environment         = "dev"
  
  subnet_configs = {
    function_app = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.KeyVault"
      ]
      delegation = {
        name         = "delegation-function-app"
        service_name = "Microsoft.Web/serverFarms"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    
    private_endpoints = {
      address_prefixes  = ["10.0.3.0/24"]
      service_endpoints = []
    }
    
    data = {
      address_prefixes = ["10.0.4.0/24"]
      service_endpoints = [
        "Microsoft.AzureCosmosDB"
      ]
    }
  }
  
  nsg_ids = {
    function_app      = azurerm_network_security_group.function_app.id
    private_endpoints = azurerm_network_security_group.private_endpoints.id
    data              = azurerm_network_security_group.data.id
  }
}

# Reference subnet IDs
resource "azurerm_private_endpoint" "example" {
  subnet_id = module.virtualsubnet.subnet_ids["private_endpoints"]
  # ... other config
}
```

---

## 📂 Module Structure

```
virtualsubnet/
├── main.tf       # Subnet and NSG association resources
├── variables.tf  # Input variable definitions
├── outputs.tf    # Output value definitions
└── README.md     # This file
```

---

## 🔐 Best Practices

✅ **Subnet Sizing**: Use /24 (256 IPs) for most subnets, /27 (32 IPs) minimum  
✅ **Service Endpoints**: Enable only required services to reduce attack surface  
✅ **Delegations**: Required for App Service VNet integration  
✅ **NSG Association**: Always associate NSGs for network-level security  
✅ **Address Planning**: Reserve addresses (Azure uses first 4 and last 1 in each subnet)  
✅ **Naming**: Use descriptive keys like `function_app`, `database`, `private_endpoints`

### Common Service Endpoints

| Service | Endpoint Name | Use Case |
|---------|---------------|----------|
| Storage | `Microsoft.Storage` | Blob, File, Queue access |
| SQL | `Microsoft.Sql` | Azure SQL Database |
| Cosmos DB | `Microsoft.AzureCosmosDB` | Cosmos DB access |
| Key Vault | `Microsoft.KeyVault` | Secrets access |
| Service Bus | `Microsoft.ServiceBus` | Message queuing |

### Subnet Address Planning

For a /16 VNet (10.0.0.0/16):

```hcl
subnet_configs = {
  function_app      = { address_prefixes = ["10.0.1.0/24"] }  # 251 usable IPs
  private_endpoints = { address_prefixes = ["10.0.3.0/24"] }  # 251 usable IPs
  data              = { address_prefixes = ["10.0.4.0/24"] }  # 251 usable IPs
  app_gateway       = { address_prefixes = ["10.0.10.0/24"] } # Future use
  bastion           = { address_prefixes = ["10.0.20.0/24"] } # Future use
}
```

---

## 🧪 Testing

```bash
# Navigate to module directory
cd modules/virtualsubnet

# Initialize
terraform init

# Validate
terraform validate

# Plan with example config
terraform plan \
  -var="vnet_name=vnet-test" \
  -var="resource_group_name=rg-test" \
  -var="environment=dev" \
  -var='subnet_configs={"test":{"address_prefixes":["10.0.1.0/24"],"service_endpoints":[]}}'

# Apply
terraform apply

# Verify subnets
az network vnet subnet list --vnet-name vnet-test --resource-group rg-test
```

---

## 🔧 Advanced Configurations

### App Service VNet Integration Subnet

```hcl
function_app = {
  address_prefixes  = ["10.0.1.0/24"]
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.AzureCosmosDB"
  ]
  delegation = {
    name         = "delegation-function-app"
    service_name = "Microsoft.Web/serverFarms"
    actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
  }
}
```

### Private Endpoint Subnet (No Delegation)

```hcl
private_endpoints = {
  address_prefixes  = ["10.0.3.0/24"]
  service_endpoints = []
  # No delegation - private endpoints don't support it
}
```

### Data Subnet with Cosmos DB Service Endpoint

```hcl
data = {
  address_prefixes = ["10.0.4.0/24"]
  service_endpoints = [
    "Microsoft.AzureCosmosDB"
  ]
}
```

---

## 🐛 Troubleshooting

**Issue**: Subnet creation fails with address overlap  
**Solution**: Ensure address_prefixes don't overlap with existing subnets or VNet address space

**Issue**: Service endpoint not working  
**Solution**: Verify the PaaS service has firewall rules allowing the subnet

**Issue**: Private endpoint deployment fails  
**Solution**: Check `private_endpoint_network_policies = "Disabled"` is set (automatic in this module)

**Issue**: App Service VNet integration fails  
**Solution**: Ensure delegation is configured for `Microsoft.Web/serverFarms`

---

## 📘 References

- [Azure Subnets Documentation](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-subnet)
- [Terraform azurerm_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet)
- [Virtual Network Service Endpoints](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview)
- [Subnet Delegation](https://learn.microsoft.com/en-us/azure/virtual-network/subnet-delegation-overview)

---

## 👤 Maintainer

This module is part of the DTE Employee Management application infrastructure.  
Maintained by: DTE DevOps Team
