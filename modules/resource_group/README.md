# Resource Group Terraform Module

## 📘 Overview

This Terraform module creates an **Azure Resource Group**, which serves as a logical container for all Azure resources in your deployment. Resource Groups provide a way to organize, manage, and apply policies to resources as a single unit.

---

## ✅ Features

- **Simple Resource Group Creation**: Minimal configuration required
- **Tagging Support**: Apply consistent tags for organization and billing
- **Location Flexibility**: Deploy to any Azure region
- **Lifecycle Management**: Managed through Terraform state

---

## ⚠️ Requirements

- **Terraform**: >= 1.5.0
- **Azure Provider**: ~> 4.0
- **Azure Subscription**: Valid subscription with Contributor access

---

## 📦 Resources Created

- `azurerm_resource_group`: Azure Resource Group container

---

## 🧩 Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `resource_group_name` | Name of the resource group | string | - | ✅ |
| `location` | Azure region for the resource group | string | - | ✅ |
| `tags` | Tags to apply to the resource group | map(string) | `{}` | ❌ |

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `resource_group_name` | Name of the created resource group |
| `resource_group_location` | Location/region of the resource group |
| `resource_group_id` | Azure resource ID of the resource group |

---

## 🚀 Usage Example

```hcl
module "resource_group" {
  source = "./modules/resource_group"

  resource_group_name = "rg-employee-app-dev"
  location            = "eastus2"
  
  tags = {
    Environment = "dev"
    Project     = "EmployeeManagement"
    ManagedBy   = "Terraform"
    Owner       = "team@company.com"
  }
}

# Reference outputs
output "rg_name" {
  value = module.resource_group.resource_group_name
}
```

---

## 📂 Module Structure

```
resource_group/
├── main.tf       # Resource Group resource definition
├── variables.tf  # Input variable definitions
├── outputs.tf    # Output value definitions
└── README.md     # This file
```

---

## 🔐 Best Practices

✅ **Naming Conventions**: Use consistent naming like `rg-<project>-<environment>`  
✅ **Tagging**: Always include Environment, Project, and Owner tags  
✅ **Region Selection**: Choose regions close to your users for lower latency  
✅ **Single Purpose**: Keep related resources in the same RG for easier management  
✅ **Lifecycle**: Use RG locks in production to prevent accidental deletion

---

## 🧪 Testing

```bash
# Navigate to module directory
cd modules/resource_group

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -var="resource_group_name=rg-test" -var="location=eastus2"

# Apply (creates resource group)
terraform apply -var="resource_group_name=rg-test" -var="location=eastus2"

# Destroy
terraform destroy
```

---

## 📘 References

- [Azure Resource Groups Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal)
- [Terraform azurerm_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group)
- [Azure Naming Conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)

---

## 👤 Maintainer

This module is part of the DTE Employee Management application infrastructure.  
Maintained by: DTE DevOps Team
