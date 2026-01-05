# DTE Employee Management Application - Infrastructure as Code

## 📘 Overview

This Terraform project provisions a **production-ready, enterprise-grade Azure infrastructure** for the DTE Employee Management web application. The architecture follows Azure best practices with VNet isolation, private endpoints, managed identities, and comprehensive monitoring.

### Architecture Components

- **Frontend**: Azure Static Web App for React/Vue/Angular applications
- **Backend**: Azure Function App (Python 3.11) for serverless API
- **Database**: Azure Cosmos DB (SQL API) with private endpoint
- **Security**: Azure Key Vault for secrets, RBAC-based access control
- **Networking**: Virtual Network with isolated subnets and NSGs
- **Monitoring**: Log Analytics Workspace + Application Insights
- **DNS**: Private DNS Zones for secure private endpoint resolution

---

## ✅ Features

- **Zero-Trust Networking**: All resources deployed within VNet with private endpoints
- **Secure by Default**: Public network access disabled, HTTPS-only, RBAC-enabled
- **High Availability**: Zone-redundant infrastructure components
- **Comprehensive Monitoring**: Centralized logging and application performance monitoring
- **Enterprise Compliance**: Meets security standards with pre-commit hooks (tflint, tfsec, terraform-docs)
- **Infrastructure as Code**: Fully automated deployment with GitHub Actions workflows
- **Environment Isolation**: Separate configurations for dev, staging, and production

---

## 🏗️ Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Cloud                              │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Virtual Network (10.0.0.0/16)               │  │
│  │                                                          │  │
│  │  ┌────────────────┐  ┌────────────────┐  ┌───────────┐ │  │
│  │  │ Function App   │  │ Private        │  │   Data    │ │  │
│  │  │ Subnet         │  │ Endpoints      │  │  Subnet   │ │  │
│  │  │ (10.0.1.0/24)  │  │ (10.0.3.0/24)  │  │(10.0.4.0/24)│ │
│  │  └────────────────┘  └────────────────┘  └───────────┘ │  │
│  │         │                    │                  │        │  │
│  │         ▼                    ▼                  ▼        │  │
│  │  ┌────────────────┐  ┌────────────────┐  ┌───────────┐ │  │
│  │  │ Function App   │  │ Key Vault PE   │  │ Cosmos DB │ │  │
│  │  │ (VNet Integ.)  │  │ Cosmos DB PE   │  │ (Private) │ │  │
│  │  └────────────────┘  │ Storage PE     │  └───────────┘ │  │
│  │                      └────────────────┘                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────┐   ┌──────────────────┐                  │
│  │ Static Web App   │   │ App Insights +   │                  │
│  │ (Public)         │───│ Log Analytics    │                  │
│  └──────────────────┘   └──────────────────┘                  │
│           │                                                    │
│           ▼                                                    │
│  ┌──────────────────┐                                         │
│  │ Function App API │ (HTTPS)                                 │
│  │ (Backend)        │                                         │
│  └──────────────────┘                                         │
└─────────────────────────────────────────────────────────────────┘

Data Flow:
1. User → Static Web App → Function App API
2. Function App → Private Endpoint → Cosmos DB
3. Function App → Private Endpoint → Key Vault (Secrets)
4. All services → Log Analytics Workspace (Logs/Metrics)
```

---

## ⚠️ Requirements

### Tools & Versions

- **Terraform**: >= 1.5.0
- **Azure CLI**: >= 2.50.0
- **Python**: 3.11+ (for Function App development)
- **Git**: For version control
- **Pre-commit**: For code quality checks

### Azure Prerequisites

- Active Azure Subscription with sufficient quota
- Azure AD permissions to create service principals
- Resource Provider registrations:
  - `Microsoft.Web`
  - `Microsoft.DocumentDB`
  - `Microsoft.KeyVault`
  - `Microsoft.Network`
  - `Microsoft.Storage`
  - `Microsoft.Insights`

### Local Development Tools (Optional but Recommended)

```bash
# Install pre-commit hooks
pip install pre-commit

# Install security scanning tools
choco install tflint tfsec terraform-docs  # Windows
brew install tflint tfsec terraform-docs    # macOS
```

---

## 📦 Resources Created

| Resource Type | Count | Purpose |
|---------------|-------|---------|
| Resource Group | 1 | Container for all resources |
| Virtual Network | 1 | Network isolation (10.0.0.0/16) |
| Subnets | 3 | Function App, Private Endpoints, Data |
| Network Security Groups | 3 | Subnet-level firewall rules |
| Log Analytics Workspace | 1 | Centralized logging |
| Application Insights | 1 | APM and monitoring |
| Key Vault | 1 | Secrets management |
| Cosmos DB Account | 1 | NoSQL database |
| Cosmos DB SQL Database | 1 | Employee data |
| Cosmos DB Container | 1 | Employee collection |
| Function App | 1 | Backend API (Python 3.11) |
| App Service Plan | 1 | Elastic Premium EP1 |
| Storage Account | 1 | Function App content |
| Static Web App | 1 | Frontend hosting |
| Private Endpoints | 5 | Key Vault, Cosmos DB, Storage (Blob, File) |
| Private DNS Zones | 1+ | privatelink.documents.azure.com |
| RBAC Role Assignments | 4+ | Managed identity permissions |

**Total Estimated Monthly Cost (Dev)**: ~$150-200 USD  
**Total Estimated Monthly Cost (Prod)**: ~$500-800 USD

---

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone <repository-url>
cd azure/DTE/terraform
```

### 2. Configure Azure Authentication

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "<subscription-id>"

# Create service principal for Terraform (optional for local)
az ad sp create-for-rbac --name "terraform-dte-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/<subscription-id>"
```

### 3. Initialize Terraform Backend

```bash
# Edit backend.tf with your storage account details
# Then initialize
terraform init
```

### 4. Configure Environment Variables

```bash
# Copy example tfvars
cp dev.tfvars terraform.tfvars

# Edit terraform.tfvars with your values
# Key variables:
# - environment: dev/stg/prod
# - project_name: emp (or your project code)
# - azure_region: eastus2 (or your preferred region)
```

### 5. Deploy Infrastructure

```bash
# Validate configuration
terraform validate

# Preview changes
terraform plan -var-file="dev.tfvars"

# Apply changes
terraform apply -var-file="dev.tfvars"

# Save outputs
terraform output > outputs.txt
```

### 6. Deploy Application Code

After infrastructure is ready, use the GitHub Actions workflow:

```bash
# Push code to trigger deployment
git push origin main

# Or manually trigger workflow in GitHub UI:
# Actions → Deploy Infrastructure and Application → Run workflow
```

---

## 📂 Project Structure

```
terraform/
├── .github/
│   └── workflows/
│       ├── deploy.yml           # Infrastructure deployment workflow
│       ├── destroy.yml          # Infrastructure destruction workflow
│       └── deploy-app-only.yml  # Application-only deployment
├── app/
│   ├── backend/                 # Python Function App code
│   └── frontend/                # Static Web App code
├── modules/                     # Reusable Terraform modules
│   ├── app_insights/           # Application Insights module
│   ├── cosmos_db/              # Cosmos DB with private endpoint
│   ├── function_app/           # Function App with VNet integration
│   ├── key_vault/              # Key Vault with RBAC
│   ├── log_analytics/          # Log Analytics Workspace
│   ├── private_dns_zone/       # Private DNS Zone management
│   ├── resource_group/         # Resource Group
│   ├── securitygroup/          # Network Security Groups
│   ├── static_web_app/         # Static Web App
│   ├── virtualnetwork/         # Virtual Network
│   └── virtualsubnet/          # Subnet configurations
├── scripts/                     # Deployment helper scripts
│   └── seed-data.sh            # Cosmos DB data seeding
├── appInsights.tf              # Application Insights config
├── backend.tf                  # Terraform remote backend
├── cosmosDb.tf                 # Cosmos DB deployment
├── data.tf                     # Data sources
├── dev.tfvars                  # Development environment
├── functionApp.tf              # Function App configuration
├── keyVault.tf                 # Key Vault deployment
├── locals.tf                   # Local values and naming
├── logAnalytics.tf             # Log Analytics workspace
├── main.tf                     # Main entry point (documentation)
├── outputs.tf                  # Output values
├── prod.tfvars                 # Production environment
├── provider.tf                 # Azure provider config
├── rbac.tf                     # RBAC role assignments
├── resourceGroup.tf            # Resource Group module
├── securityGroup.tf            # NSG rules
├── staticWebApp.tf             # Static Web App
├── variables.tf                # Input variable definitions
├── versions.tf                 # Provider version constraints
├── virtualNetwork.tf           # VNet deployment
├── virtualSubnet.tf            # Subnet configurations
├── .pre-commit-config.yaml     # Pre-commit hooks config
└── README.md                   # This file
```

---

## 🧩 Input Variables

See [variables.tf](variables.tf) for complete list. Key variables:

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `environment` | Environment name (dev/stg/prod) | string | - | ✅ |
| `project_name` | Project name for resource naming | string | - | ✅ |
| `azure_region` | Azure region for deployment | string | `eastus2` | ❌ |
| `vnet_address_space` | VNet CIDR blocks | list(string) | `["10.0.0.0/16"]` | ❌ |
| `cosmos_db_throughput` | Cosmos DB RU/s | number | `400` | ❌ |
| `function_app_runtime` | Runtime (python/node/dotnet) | string | `python` | ❌ |
| `function_app_runtime_version` | Runtime version | string | `3.11` | ❌ |
| `enable_monitoring` | Enable App Insights | bool | `true` | ❌ |
| `log_retention_days` | Log retention period | number | `30` | ❌ |
| `owner_email` | Resource owner email | string | `team@company.com` | ❌ |
| `cost_center` | Billing cost center | string | `IT` | ❌ |
| `tags` | Additional resource tags | map(string) | `{}` | ❌ |

---

## 📤 Outputs

After deployment, Terraform outputs critical information:

```bash
terraform output
```

| Output | Description |
|--------|-------------|
| `resource_group_name` | Name of the resource group |
| `function_app_name` | Function App name |
| `function_app_url` | Function App default hostname |
| `static_web_app_url` | Static Web App URL |
| `cosmos_db_endpoint` | Cosmos DB endpoint |
| `key_vault_name` | Key Vault name |
| `app_insights_instrumentation_key` | Application Insights key |
| `vnet_id` | Virtual Network ID |
| `function_app_principal_id` | Function App managed identity |

---

## 🔐 Security & Compliance

### Implemented Security Controls

✅ **Network Security**
- Private endpoints for all PaaS services
- Public network access disabled on Cosmos DB and Key Vault
- NSG rules restricting inbound/outbound traffic
- VNet integration for Function App outbound traffic

✅ **Identity & Access**
- System-assigned managed identities (no passwords)
- RBAC-based access control (least privilege)
- Azure AD authentication only
- Secrets stored in Key Vault

✅ **Data Protection**
- TLS 1.2 minimum for all services
- HTTPS-only enforced
- Soft delete + purge protection on Key Vault
- Encryption at rest (Azure-managed keys)

✅ **Monitoring & Compliance**
- Centralized logging to Log Analytics
- Diagnostic settings on all resources
- Application Insights telemetry
- Audit logs retained per policy

### Pre-commit Hooks

This project uses pre-commit hooks for code quality:

```yaml
# Enabled hooks:
- terraform_fmt         # Format Terraform code
- terraform_validate    # Validate syntax
- terraform_tflint      # Linting (best practices)
- terraform_tfsec       # Security scanning
- terraform_docs        # Auto-generate documentation
```

**Setup:**

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

### Security Scanning Results

All modules pass `tfsec` and `checkov` security scans. See individual module READMEs for detailed scan results.

---

## 🧪 Testing

### Local Testing

```bash
# Format code
terraform fmt -recursive

# Validate syntax
terraform validate

# Security scan
tfsec .

# Linting
tflint --recursive

# Plan without applying
terraform plan -var-file="dev.tfvars"
```

### CI/CD Testing

GitHub Actions workflows automatically run:
- Pre-commit hooks (fmt, validate, tflint, tfsec, docs)
- Terraform plan with approval gate
- Apply with manual approval (tf-apply environment)

---

## 🔄 CI/CD Workflows

### Infrastructure Deployment ([.github/workflows/deploy.yml](.github/workflows/deploy.yml))

**Trigger**: Manual or push to `main`

**Jobs**:
1. **Pre-commit**: Runs code quality checks
2. **Terraform Plan**: Generates plan, uploads artifact
3. **Terraform Apply**: Requires approval via `tf-apply` environment

**Setup Required**:
- Create GitHub environment `tf-apply` with required reviewers
- Add `AZURE_CREDENTIALS` secret (service principal JSON)

### Infrastructure Destruction ([.github/workflows/destroy.yml](.github/workflows/destroy.yml))

**Trigger**: Manual workflow dispatch with confirmation

**Jobs**:
1. **Validate Input**: Ensures user types "DESTROY" to confirm
2. **Terraform Destroy Plan**: Shows what will be deleted
3. **Terraform Destroy**: Requires approval via `tf-destroy` environment

**Safety Features**:
- Double confirmation required
- Plan review before destruction
- Approval gate prevents accidental deletion

### Application Deployment ([.github/workflows/deploy-app-only.yml](.github/workflows/deploy-app-only.yml))

**Trigger**: Manual or push to `app/` directory

**Jobs**:
1. **Deploy Backend**: Uploads Function App code
2. **Deploy Frontend**: Builds and deploys Static Web App
3. **Seed Data**: Populates Cosmos DB with sample data
4. **Verify**: Tests API endpoints

---

## 📖 Module Documentation

Each module has comprehensive documentation:

- [app_insights](modules/app_insights/README.md) - Application monitoring
- [cosmos_db](modules/cosmos_db/README.md) - NoSQL database with private endpoint
- [function_app](modules/function_app/README.md) - Serverless API with VNet integration
- [key_vault](modules/key_vault/README.md) - Secrets management with RBAC
- [log_analytics](modules/log_analytics/README.md) - Centralized logging
- [private_dns_zone](modules/private_dns_zone/README.md) - DNS resolution for private endpoints
- [resource_group](modules/resource_group/README.md) - Resource container
- [securitygroup](modules/securitygroup/README.md) - Network security rules
- [static_web_app](modules/static_web_app/README.md) - Frontend hosting
- [virtualnetwork](modules/virtualnetwork/README.md) - Virtual network
- [virtualsubnet](modules/virtualsubnet/README.md) - Subnet configurations

---

## 🐛 Troubleshooting

### Common Issues

**Issue**: Function App cannot connect to Cosmos DB  
**Solution**: Verify Private DNS Zone is linked to VNet. Check [cosmosDb.tf](cosmosDb.tf) for DNS zone configuration.

**Issue**: `terraform init` fails with backend error  
**Solution**: Ensure storage account exists and credentials are correct in [backend.tf](backend.tf).

**Issue**: Pre-commit hooks fail with "command not found"  
**Solution**: Install tools locally or let CI handle validation:
```bash
choco install tflint tfsec terraform-docs  # Windows
brew install tflint tfsec terraform-docs    # macOS
```

**Issue**: GitHub Actions deployment fails at approval step  
**Solution**: Create `tf-apply` environment in repo Settings → Environments and add required reviewers.

**Issue**: Static Web App shows "Failed to load data"  
**Solution**: Check Function App logs, verify CORS settings, ensure managed identity has Cosmos DB data access.

### Debugging

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
terraform plan -var-file="dev.tfvars"

# View Function App logs
az functionapp log tail --name <function-app-name> --resource-group <rg-name>

# Check Cosmos DB connectivity
az cosmosdb show --name <cosmos-name> --resource-group <rg-name>

# Verify RBAC assignments
az role assignment list --assignee <principal-id> --all
```

---

## 🔧 Customization

### Adding a New Environment

1. Copy `dev.tfvars` to `<env>.tfvars`
2. Update environment-specific values
3. Deploy: `terraform apply -var-file="<env>.tfvars"`

### Changing Region

Update `azure_region` in tfvars file:

```hcl
azure_region = "westus2"  # Or any Azure region
```

### Scaling Cosmos DB

Adjust throughput in tfvars:

```hcl
cosmos_db_throughput = 1000  # RU/s (400 minimum)
```

### Adding Custom Tags

```hcl
tags = {
  Department = "Engineering"
  Project    = "EmployeeManagement"
  CostCenter = "CC-12345"
}
```

---

## 📘 References

- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/architecture/framework/)
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Function App Best Practices](https://learn.microsoft.com/en-us/azure/azure-functions/functions-best-practices)
- [Cosmos DB Security Guide](https://learn.microsoft.com/en-us/azure/cosmos-db/security)
- [Azure Private Endpoint Documentation](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview)

---

## 👥 Support & Contribution

### Getting Help

- **Internal Team**: Contact DevOps team at team@company.com
- **Issues**: Create GitHub issue for bugs/feature requests
- **Documentation**: See individual module READMEs

### Contributing

1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes and test locally
3. Run pre-commit hooks: `pre-commit run --all-files`
4. Submit pull request with description
5. Wait for review and approval

---

## 📋 Change Log

### v1.0.0 (Current)
- Initial release with core infrastructure
- VNet isolation with private endpoints
- Managed identity authentication
- GitHub Actions CI/CD workflows
- Pre-commit hooks for quality

### Planned Enhancements
- Multi-region deployment support
- Custom domain for Static Web App
- Azure Front Door integration
- Automated backup/restore procedures

---

## 👤 Maintainer

**DTE Infrastructure Team**  
Email: team@company.com  
Department: IT - DevOps

---

## 📄 License

Internal use only - Proprietary software  
Copyright © 2026 DTE Company
