# Secure Azure Employee Management System

A **production-ready, enterprise-grade** employee management application with secure Azure infrastructure using Terraform and Python backend.

## 📋 Quick Links for Interview

- 🔐 **[INTERVIEW_SUBMISSION_SUMMARY.md](INTERVIEW_SUBMISSION_SUMMARY.md)** - Start here! Complete overview of the enterprise solution
- 🔒 **[SECURITY_IMPLEMENTATION.md](SECURITY_IMPLEMENTATION.md)** - Deep-dive into identity, RBAC, and network security
- 🚀 **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Step-by-step deployment and troubleshooting

> **Enterprise Features Implemented:**
> - ✅ Azure Managed Identity (System-Assigned) for all services
> - ✅ Role-Based Access Control (RBAC) on Cosmos DB, Key Vault, Storage
> - ✅ Network Isolation: VNet integration, private endpoints, service endpoints
> - ✅ Zero credential exposure in code or environment variables
> - ✅ Comprehensive monitoring via Application Insights & Log Analytics
> - ✅ Python backend using DefaultAzureCredential for cloud-native auth

---

## 🚀 Three Deployment Options (Simplest → Enterprise)

| Option | Difficulty | Best For | Time |
|--------|------------|----------|------|
| **Option 1: Local** | ⭐ Easiest | Quick testing | ~10 min |
| **Option 2: Cloud Shell** | ⭐⭐ Medium | When local tools aren't available | ~15 min |
| **Option 3: GitHub Actions** | ⭐⭐⭐ Enterprise | Production, CI/CD, Team collaboration | ~20 min setup |

---

## Option 1: Local Deployment (Simplest)

Deploy everything from your local machine using PowerShell.

### Prerequisites
- Azure CLI (`az login`)
- Terraform >= 1.0
- Python >= 3.11 + Azure Functions Core Tools v4
- Node.js >= 18

### Steps

```powershell
# 1. Clone and navigate
git clone https://github.com/tilakmishra/azure-terraform-webapp.git
cd azure-terraform-webapp

# 2. Deploy infrastructure
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# 3. Get the names from terraform output
$FunctionAppName = terraform output -raw function_app_name
$StaticWebAppName = terraform output -raw static_web_app_name
$ResourceGroup = terraform output -raw resource_group_name

# 4. Run the deployment script
.\scripts\deploy-simple.ps1 -FunctionAppName $FunctionAppName -StaticWebAppName $StaticWebAppName -ResourceGroupName $ResourceGroup
```

**Done!** Your app is live.

---

## Option 2: Azure Cloud Shell (No Local Setup)

Perfect when you don't have tools installed locally or are on a restricted machine.

### Steps

1. **Deploy Infrastructure** from Cloud Shell or locally:
   ```bash
   terraform init && terraform apply -var-file="dev.tfvars"
   ```

2. **Open Azure Cloud Shell**: Go to [portal.azure.com](https://portal.azure.com) → Click Cloud Shell icon (top right)

3. **Run deployment script**:
   ```bash
   # Clone repo
   git clone https://github.com/tilakmishra/azure-terraform-webapp.git
   cd azure-terraform-webapp/scripts
   
   # Edit deploy-cloudshell.sh with your resource names, then:
   chmod +x deploy-cloudshell.sh
   ./deploy-cloudshell.sh
   ```

---

## Option 3: GitHub Actions CI/CD (Enterprise)

Fully automated deployment pipeline. Push code → Everything deploys automatically.

### Step 1: Fork the Repository
Click "Fork" on GitHub to create your own copy.

### Step 2: Create Azure Service Principal
```bash
az login
az ad sp create-for-rbac --name "github-actions-sp" --role contributor \
  --scopes /subscriptions/<YOUR_SUBSCRIPTION_ID> \
  --sdk-auth
```
Copy the JSON output.

### Step 3: Add GitHub Secrets
Go to your forked repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:

| Secret Name | Value |
|-------------|-------|
| `AZURE_CREDENTIALS` | The JSON output from Step 2 |
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | Get from Azure Portal after first deploy |

### Step 4: Trigger Deployment
Push any change to `main` branch, or go to **Actions** → **"Deploy Infrastructure and Application"** → **Run workflow**.

### What GitHub Actions Does
1. ✅ Creates all Azure infrastructure with Terraform
2. ✅ Deploys Python Function App (backend API)
3. ✅ Deploys React Static Web App (frontend)
4. ✅ Seeds sample employee data
5. ✅ Runs on every push to main (continuous deployment)

## Architecture

```
User's Browser
      │
      │ HTTPS
      ├─────────────────────────┐
      ▼                         ▼
┌──────────────┐    ┌───────────────────────────────────────┐
│ Static Web   │    │       Virtual Network (10.0.0.0/16)   │
│    App       │    │                                       │
│  (React)     │    │  ┌─────────────────────────────────┐  │
│              │    │  │    Function App Subnet          │  │
│   Public     │────┼─▶│    (Python API)                 │  │
└──────────────┘    │  │    VNet Integrated              │  │
                    │  └──────────────┬──────────────────┘  │
                    │                 │                     │
                    │                 │ Private             │
                    │                 ▼                     │
                    │  ┌─────────────────────────────────┐  │
                    │  │  Private Endpoints Subnet       │  │
                    │  │                                 │  │
                    │  │  ┌───────────┐ ┌─────────────┐  │  │
                    │  │  │ Cosmos DB │ │  Key Vault  │  │  │
                    │  │  │ (NoSQL)   │ │  (Secrets)  │  │  │
                    │  │  └───────────┘ └─────────────┘  │  │
                    │  └─────────────────────────────────┘  │
                    └───────────────────────────────────────┘
```

## Security Features

| Feature | Implementation | Why |
|---------|----------------|-----|
| **Private Endpoints** | Cosmos DB, Key Vault, Storage | No public IPs for sensitive resources |
| **VNet Integration** | Function App outbound via VNet | Backend accesses private resources |
| **NSG Rules** | Per-subnet firewall rules | Defense in depth |
| **Private DNS** | Resolves to private IPs | Enables private endpoint connectivity |
| **Managed Identity** | Function App → Cosmos DB | No passwords in config |
| **Key Vault** | Stores secrets | Centralized, auditable secret management |

## Project Structure

```
├── app/
│   ├── backend/           # Python Function App
│   │   ├── function_app.py
│   │   ├── requirements.txt
│   │   └── host.json
│   └── frontend/          # React Static Web App
│       ├── src/
│       │   ├── App.js
│       │   └── index.js
│       └── package.json
│
├── modules/               # Terraform modules
│   ├── function_app/
│   ├── static_web_app/
│   ├── cosmos_db/
│   ├── key_vault/
│   ├── virtualnetwork/
│   └── ...
│
├── scripts/
│   ├── deploy.ps1         # Windows deployment
│   └── deploy.sh          # Linux/Mac deployment
│
├── main.tf                # Root Terraform config
├── variables.tf
├── outputs.tf
├── dev.tfvars             # Development config
└── prod.tfvars            # Production config
```

## Manual Deployment Steps

### 1. Infrastructure Only
```powershell
cd terraform
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

### 2. Backend (Function App)
```powershell
cd app/backend
pip install -r requirements.txt
func azure functionapp publish <function-app-name> --python
```

### 3. Frontend (Static Web App)
```powershell
cd app/frontend
npm install
$env:REACT_APP_API_URL = "https://<function-app-name>.azurewebsites.net/api"
npm run build
# Deploy using Azure Portal or SWA CLI
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/employees` | List all employees |
| GET | `/api/employees/{id}` | Get employee by ID |
| POST | `/api/employees` | Create employee |
| PUT | `/api/employees/{id}` | Update employee |
| DELETE | `/api/employees/{id}` | Delete employee (soft) |
| GET | `/api/departments` | Get department stats |

## Resources Created

| Resource | Name Pattern | Purpose |
|----------|--------------|---------|
| Resource Group | `rg-dte-{env}` | Container |
| Virtual Network | `vnet-dte-{env}` | Network isolation |
| Function App | `func-dte-{env}-{suffix}` | Backend API |
| Static Web App | `swa-dte-{env}-{suffix}` | Frontend |
| Cosmos DB | `cosmos-dte-{env}-{suffix}` | Database |
| Key Vault | `kv-dte-{env}-{suffix}` | Secrets |
| Storage Account | `stdte{env}{suffix}` | Function storage |
| App Insights | `appi-dte-{env}` | Monitoring |

## Cleanup

```powershell
cd terraform
terraform destroy -var-file="dev.tfvars"
```

## Troubleshooting

### RBAC Error for Cosmos DB
If you see `could not find role 'Cosmos DB Built-in Data Contributor'`, the fix is already applied. Just run:
```powershell
terraform apply -var-file="dev.tfvars"
```

### Function App Not Accessible
The Function App has `public_network_access_enabled = false` by default. The Static Web App calls it via the public URL, so either:
1. Enable public access on Function App, or
2. Use API Management as a gateway

### Frontend Can't Reach Backend
Check that `REACT_APP_API_URL` is set correctly before building the frontend.

---

*Built with Terraform for Azure*
