# Employee Management Infrastructure

Modern, secure Azure infrastructure for employee management application deployed via **GitHub Actions with OIDC authentication**.

## 🎯 Quick Start

### Prerequisites
- Azure subscription
- GitHub repository
- Azure CLI installed

### Setup (One-time)

```bash
# 1. Run OIDC setup script
./scripts/setup-github-oidc.sh \
  --github-org YOUR_ORG \
  --github-repo YOUR_REPO \
  --azure-subscription YOUR_SUBSCRIPTION_ID

# 2. Add GitHub Secrets (from script output)
# Repository Settings → Secrets → Actions → New repository secret
#   AZURE_CLIENT_ID
#   AZURE_TENANT_ID  
#   AZURE_SUBSCRIPTION_ID

# 3. Deploy via GitHub Actions
# Push to main branch or manually trigger workflow
```

---

## ✅ Features

- **🔒 Secure Authentication**: GitHub OIDC (no long-lived credentials stored)
- **🏗️ Modular Architecture**: 11 reusable Terraform modules
- **🌍 Multi-Environment**: dev, stg, prod with isolated configurations
- **📊 Monitoring**: Application Insights + Log Analytics
- **🔐 Zero-Trust Networking**: VNet isolation with private endpoints
- **✨ Best Practices**: Underscore naming, organized variables, pre-commit hooks

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Azure Infrastructure                 │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │       Virtual Network (10.0.0.0/16)              │  │
│  │                                                  │  │
│  │  ┌──────────────┐  ┌──────────────┐            │  │
│  │  │ Function App │  │  Cosmos DB   │            │  │
│  │  │   Subnet     │  │   (Private   │            │  │
│  │  │ (10.0.1.0/24)│  │  Endpoint)   │            │  │
│  │  └──────────────┘  └──────────────┘            │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────┐   ┌──────────────┐                  │
│  │ Static Web   │   │ Monitoring:  │                  │
│  │ App (Public) │───│ App Insights │                  │
│  └──────────────┘   │ + Analytics  │                  │
│                     └──────────────┘                  │
└─────────────────────────────────────────────────────────┘

Deployment: GitHub Actions → OIDC Token → Azure → Terraform
```

## 📦 Resources Deployed

| Resource | Purpose |
|----------|---------|
| Virtual Network | Network isolation |
| Subnets (3) | Function App, Private Endpoints, Data |
| Network Security Groups | Firewall rules |
| Cosmos DB | NoSQL database with private endpoint |
| Function App | Backend API (Python 3.11) |
| App Service Plan | Elastic Premium EP1 |
| Storage Account | Function App storage |
| Static Web App | Frontend hosting |
| Log Analytics | Centralized logging |
| Application Insights | APM monitoring |
| Key Vault | Secrets management |
| Private Endpoints | Secure private connectivity |

**Estimated Cost**: Dev ~$150/mo, Prod ~$500/mo

---

## 🚀 Deployment

### GitHub Actions (Recommended)

**Authentication**: Uses GitHub OIDC - no secrets stored in GitHub!

1. **Initial Setup** (once):
   ```bash
   ./scripts/setup-github-oidc.sh \
     --github-org mycompany \
     --github-repo employee-management \
     --azure-subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```

2. **Add GitHub Secrets** (from script output):
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

3. **Deploy**:
   ```bash
   # Trigger via push
   git push origin main
   
   # Or manually via GitHub CLI
   gh workflow run deploy-oidc.yml -f environment=dev
   ```

### Local Deployment (Testing)

```bash
# Login to Azure
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="environments/dev.tfvars"

# Apply changes
terraform apply -var-file="environments/dev.tfvars"
```

---

## 📂 Project Structure

```
terraform/
├── .github/workflows/
│   └── deploy-oidc.yml         # GitHub Actions with OIDC auth
├── app/
│   ├── backend/                # Function App code
│   └── frontend/               # Static Web App code
├── environments/
│   ├── common.tfvars           # Shared configuration
│   ├── dev.tfvars              # Development overrides
│   ├── stg.tfvars              # Staging overrides
│   └── prod.tfvars             # Production overrides
├── modules/                    # 11 Reusable modules
│   ├── app_insights/
│   ├── cosmos_db/
│   ├── function_app/
│   ├── key_vault/
│   ├── log_analytics/
│   ├── private_dns_zone/
│   ├── resource_group/
│   ├── security_group/
│   ├── static_web_app/
│   ├── virtual_network/
│   └── virtual_subnet/
├── scripts/
│   └── setup-github-oidc.sh   # OIDC setup automation
├── backend.tf                 # Terraform state backend
├── data.tf                    # Data sources
├── locals.tf                  # Naming conventions
├── main.tf                    # Module orchestration
├── outputs.tf                 # Output values
├── provider.tf                # Azure provider
├── variables.tf               # Input variables
├── versions.tf                # Version constraints
└── README.md                  # This file
```

**Key Best Practices Implemented**:
- ✅ **Underscore naming** (`rg_emp_dev` not `rg-emp-dev`)
- ✅ **Centralized orchestration** (all modules in `main.tf`)
- ✅ **Environment-based configs** (`environments/` folder)
- ✅ **Pre-commit hooks** (tflint, tfsec validation)
- ✅ **OIDC authentication** (no stored credentials)

---

## 🔧 Configuration

### Environment Variables

Configured in `environments/` folder:

**common.tfvars** (shared across all environments):
```hcl
project_name              = "emp"
azure_region              = "eastus2"
owner_email               = "team@company.com"
cost_center               = "IT"
enable_monitoring         = true
function_app_runtime      = "python"
function_app_runtime_version = "3.11"
```

**dev.tfvars** (development-specific):
```hcl
environment          = "dev"
vnet_address_space   = ["10.0.0.0/16"]
cosmos_db_throughput = 400
log_retention_days   = 30
```

**stg.tfvars** (staging):
```hcl
environment          = "stg"
vnet_address_space   = ["10.1.0.0/16"]
cosmos_db_throughput = 800
log_retention_days   = 60
```

**prod.tfvars** (production):
```hcl
environment          = "prod"
vnet_address_space   = ["10.2.0.0/16"]
cosmos_db_throughput = 2000
log_retention_days   = 90
resource_suffix      = "prod001"  # Fixed suffix for prod
```

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `environment` | Environment (dev/stg/prod) | Required |
| `project_name` | Project identifier | `emp` |
| `azure_region` | Azure region | `eastus2` |
| `vnet_address_space` | VNet CIDR range | `["10.0.0.0/16"]` |
| `cosmos_db_throughput` | Cosmos DB RU/s | `400` |
| `enable_monitoring` | Enable monitoring | `true` |
| `log_retention_days` | Log retention period | `30` |

---

## 📤 Outputs

After deployment:

```bash
terraform output
```

| Output | Description |
|--------|-------------|
| `resource_group_name` | Resource group name |
| `function_app_name` | Function App name |
| `function_app_url` | Function App URL |
| `static_web_app_url` | Static Web App URL |
| `cosmos_db_endpoint` | Cosmos DB endpoint |
| `key_vault_uri` | Key Vault URI |
| `vnet_id` | Virtual Network ID |

---

## 🔐 Security Features

### GitHub OIDC Authentication

**No secrets stored in GitHub!** Instead:

1. GitHub generates short-lived OIDC token (1 hour)
2. Azure validates token against federated credential
3. Azure issues access token for deployment
4. Token expires automatically

**Benefits**:
- ✅ No long-lived credentials
- ✅ Automatic rotation
- ✅ Repo and branch-specific
- ✅ Instant revocation capability

### Infrastructure Security

- VNet isolation with private endpoints
- Network Security Groups (NSGs)
- Managed identities (no passwords)
- HTTPS-only endpoints
- RBAC-based access control
- Private Cosmos DB (no public access)

---

## 🧪 Testing & Validation

### Pre-commit Hooks

Automatically run before commits:

```bash
# Install
pre-commit install

# Run manually
pre-commit run --all-files
```

Checks:
- `tflint`: Terraform linting
- `tfsec`: Security scanning
- `terraform validate`: Syntax validation
- `terraform fmt`: Code formatting

### Manual Validation

```bash
# Format code
terraform fmt -recursive

# Validate syntax
terraform validate

# Security scan
tfsec .

# Plan without applying
terraform plan -var-file="environments/dev.tfvars"
```

---

## 📚 Documentation

- **OIDC Setup**: See `archive/GITHUB_OIDC_SETUP.md`
- **Quick Start**: See `archive/GITHUB_OIDC_QUICKSTART.md`
- **Multi-Branch**: See `archive/GITHUB_OIDC_MULTI_BRANCH.md`
- **Best Practices**: See `archive/TERRAFORM_BEST_PRACTICES.md`

---

## 🐛 Troubleshooting

### OIDC Authentication Fails

```bash
# Verify federation credential exists
az ad app federated-credential list --id $AZURE_CLIENT_ID

# Check subject matches: repo:ORG/REPO:ref:refs/heads/main
```

### Terraform State Lock

```bash
# Force unlock (use carefully!)
terraform force-unlock <LOCK_ID>
```

### Module Errors

```bash
# Re-initialize modules
terraform init -upgrade

# Clear cache
rm -rf .terraform
terraform init
```

---

## 🤝 Contributing

1. Create feature branch
2. Make changes
3. Run pre-commit hooks
4. Submit PR
5. GitHub Actions validates
6. Merge to main → Auto-deploy

---

## 📄 License

Proprietary - Internal use only

---

## 📞 Support

- **Documentation**: See `archive/` folder
- **Issues**: GitHub Issues
- **Team**: team@company.com
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
