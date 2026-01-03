# Virtual Network Terraform Module

## 📘 Overview

This Terraform module creates an **Azure Virtual Network (VNet)**, providing isolated network infrastructure for your Azure resources. The VNet enables secure communication between resources and supports network segmentation through subnets.

---

## ✅ Features

- **Custom Address Space**: Define your own IP address ranges
- **Azure Integration**: Seamlessly integrates with Azure services
- **Tagging Support**: Organize resources with metadata
- **Foundation for Subnets**: Base network for subnet creation

---

## ⚠️ Requirements

- **Terraform**: >= 1.5.0
- **Azure Provider**: ~> 4.0
- **Existing Resource Group**: Resource group must exist before VNet creation

---

## 📦 Resources Created

- `azurerm_virtual_network`: Azure Virtual Network

---

## 🧩 Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `name` | Name of the virtual network | string | - | ✅ |
| `location` | Azure region for the VNet | string | - | ✅ |
| `resource_group_name` | Name of the resource group | string | - | ✅ |
| `address_space` | List of address spaces (CIDR notation) | list(string) | - | ✅ |
| `tags` | Tags to apply to the VNet | map(string) | `{}` | ❌ |

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `virtual_network_id` | Azure resource ID of the VNet |
| `virtual_network_name` | Name of the VNet |
| `address_space` | Address space of the VNet |

---

## 🚀 Usage Example

```hcl
module "virtualnetwork" {
  source = "./modules/virtualnetwork"

  name                = "vnet-employee-app-dev"
  location            = "eastus2"
  resource_group_name = "rg-employee-app-dev"
  address_space       = ["10.0.0.0/16"]
  
  tags = {
    Environment = "dev"
    Project     = "EmployeeManagement"
    ManagedBy   = "Terraform"
  }
}

# Use VNet in subnet module
module "subnets" {
  source = "./modules/virtualsubnet"
  
  vnet_name           = module.virtualnetwork.virtual_network_name
  resource_group_name = module.virtualnetwork.resource_group_name
  # ... other subnet config
}
```

---

## 📂 Module Structure

```
virtualnetwork/
├── main.tf       # VNet resource definition
├── variables.tf  # Input variable definitions
├── outputs.tf    # Output value definitions
└── README.md     # This file
```

---

## 🔐 Best Practices

✅ **Address Planning**: Plan address space to avoid overlap with on-premises networks  
✅ **Size Appropriately**: Use /16 for enterprise, /24 for small deployments  
✅ **Reserve Space**: Leave room for future subnet growth  
✅ **Naming Convention**: Use `vnet-<project>-<environment>` format  
✅ **Region Alignment**: Deploy VNet in the same region as resources  
✅ **Documentation**: Document subnet allocation plan

### Recommended Address Spaces

| Environment | Address Space | Capacity |
|-------------|---------------|----------|
| Development | 10.0.0.0/16 | 65,536 IPs |
| Staging | 10.1.0.0/16 | 65,536 IPs |
| Production | 10.2.0.0/16 | 65,536 IPs |

---

## 🧪 Testing

```bash
# Navigate to module directory
cd modules/virtualnetwork

# Initialize
terraform init

# Validate
terraform validate

# Plan
terraform plan \
  -var="name=vnet-test" \
  -var="location=eastus2" \
  -var="resource_group_name=rg-test" \
  -var='address_space=["10.0.0.0/16"]'

# Apply
terraform apply

# Verify VNet creation
az network vnet show --name vnet-test --resource-group rg-test
```

---

## 🔧 Advanced Configuration

### Multiple Address Spaces

```hcl
module "virtualnetwork" {
  source = "./modules/virtualnetwork"

  name                = "vnet-multi-range"
  location            = "eastus2"
  resource_group_name = "rg-network"
  
  # Multiple non-overlapping address spaces
  address_space = [
    "10.0.0.0/16",
    "10.1.0.0/16"
  ]
  
  tags = var.tags
}
```

---

## 📘 References

- [Azure Virtual Network Documentation](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview)
- [Terraform azurerm_virtual_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network)
- [Azure IP Addressing Best Practices](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/plan-for-ip-addressing)

---

## 👤 Maintainer

This module is part of the DTE Employee Management application infrastructure.  
Maintained by: DTE DevOps Team
