# Static Web App Terraform Module

## 📘 Overview

This Terraform module creates an **Azure Static Web App** for hosting modern web applications (React, Vue, Angular, Blazor) with built-in CI/CD, global CDN, and serverless API integration. Perfect for frontend applications that consume backend APIs.

---

## ✅ Features

- **Free Tier**: Zero cost for development and small production apps
- **Global CDN**: Automatic worldwide content distribution
- **Automatic SSL**: Free managed certificates
- **CI/CD Integration**: GitHub Actions built-in
- **Custom Domains**: Support for custom domain names
- **Serverless APIs**: Optional API routes via Azure Functions
- **Authentication**: Built-in identity providers (future enhancement)
- **Simple Configuration**: Minimal setup required

---

## ⚠️ Requirements

- **Terraform**: >= 1.5.0
- **Azure Provider**: ~> 4.0
- **GitHub Repository**: (Optional) For automatic CI/CD

---

## 📦 Resources Created

- `azurerm_static_web_app`: Static Web App instance

---

## 🧩 Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `name` | Static Web App name | string | - | ✅ |
| `location` | Azure region | string | - | ✅ |
| `resource_group_name` | Resource group name | string | - | ✅ |
| `sku_size` | SKU size (Free or Standard) | string | `"Free"` | ❌ |
| `sku_tier` | SKU tier (Free or Standard) | string | `"Free"` | ❌ |
| `tags` | Resource tags | map(string) | `{}` | ❌ |

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `static_web_app_id` | Static Web App resource ID |
| `static_web_app_name` | Static Web App name |
| `default_hostname` | Default hostname (*.azurestaticapps.net) |
| `api_key` | Deployment API key (sensitive) |

---

## 🚀 Usage Example

### Basic Static Web App

```hcl
module "static_web_app" {
  source = "./modules/static_web_app"

  name                = "swa-employee-portal-dev"
  location            = "eastus2"
  resource_group_name = "rg-employee-app-dev"
  
  sku_size = "Free"
  sku_tier = "Free"
  
  tags = {
    Environment = "dev"
    Project     = "EmployeeManagement"
  }
}

# Output the URL
output "static_web_app_url" {
  value = "https://${module.static_web_app.default_hostname}"
}
```

### Production with Standard SKU

```hcl
module "static_web_app" {
  source = "./modules/static_web_app"

  name                = "swa-employee-portal-prod"
  location            = "eastus2"
  resource_group_name = "rg-employee-app-prod"
  
  sku_size = "Standard"  # Production tier
  sku_tier = "Standard"
  
  tags = {
    Environment = "production"
    Project     = "EmployeeManagement"
    CostCenter  = "IT-12345"
  }
}
```

---

## 📂 Module Structure

```
static_web_app/
├── main.tf       # Static Web App resource
├── variables.tf  # Input variable definitions
├── outputs.tf    # Output value definitions
└── README.md     # This file
```

---

## 🏗️ Application Architecture

```
┌────────────────────────────────────────────────────────┐
│                 Azure Static Web App                   │
│                                                        │
│  ┌──────────────────────────────────────────────┐    │
│  │          Frontend (React/Vue/Angular)        │    │
│  │              Static Content                  │    │
│  │         (HTML, CSS, JS, Images)              │    │
│  └──────────────────────────────────────────────┘    │
│                        │                              │
│                        ▼                              │
│  ┌──────────────────────────────────────────────┐    │
│  │           API Routes (Optional)              │    │
│  │        Serverless Functions (Node/Python)    │    │
│  └──────────────────────────────────────────────┘    │
│                        │                              │
└────────────────────────────────────────────────────────┘
                         │
                         ▼
            ┌────────────────────────┐
            │   Backend Function App │
            │   (External API)       │
            └────────────────────────┘
```

---

## 🚀 Deployment Methods

### Method 1: GitHub Actions (Automatic)

Static Web Apps automatically creates a GitHub Actions workflow:

```yaml
# .github/workflows/azure-static-web-apps-<name>.yml
name: Deploy Static Web App

on:
  push:
    branches:
      - main
  pull_request:
    types: [opened, synchronize, reopened, closed]
    branches:
      - main

jobs:
  build_and_deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: "upload"
          app_location: "/app/frontend"    # Frontend code location
          api_location: ""                 # API code location (optional)
          output_location: "build"         # Build output directory
```

### Method 2: Manual Deployment via CLI

```bash
# Install SWA CLI
npm install -g @azure/static-web-apps-cli

# Deploy from local
swa deploy \
  --app-location ./app/frontend \
  --output-location build \
  --deployment-token "<api-key-from-terraform-output>"
```

### Method 3: ZIP Deployment

```bash
# Build frontend
cd app/frontend
npm install
npm run build

# Create deployment package
cd build
zip -r ../build.zip .

# Deploy using API key
curl -X POST \
  -H "Content-Type: application/zip" \
  --data-binary @build.zip \
  "https://<static-web-app-name>.azurestaticapps.net/api/zipdeploy?token=<api-key>"
```

---

## ⚙️ Configuration File

Create `staticwebapp.config.json` in your repository root:

```json
{
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": ["/api/*", "/images/*", "/*.{css,js,png,jpg,gif}"]
  },
  "routes": [
    {
      "route": "/api/*",
      "allowedRoles": ["authenticated"]
    },
    {
      "route": "/admin/*",
      "allowedRoles": ["administrator"]
    }
  ],
  "responseOverrides": {
    "404": {
      "rewrite": "/404.html"
    }
  },
  "globalHeaders": {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Content-Security-Policy": "default-src 'self'"
  },
  "mimeTypes": {
    ".json": "application/json"
  }
}
```

---

## 🔧 Frontend Integration with Backend

### React Example

```javascript
// app/frontend/src/services/api.js
const API_BASE_URL = process.env.REACT_APP_API_URL || 
  'https://func-emp-api-dev.azurewebsites.net';

export const getEmployees = async () => {
  const response = await fetch(`${API_BASE_URL}/api/employees`);
  if (!response.ok) {
    throw new Error('Failed to fetch employees');
  }
  return response.json();
};

export const createEmployee = async (employee) => {
  const response = await fetch(`${API_BASE_URL}/api/employees`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(employee),
  });
  return response.json();
};
```

### Environment Variables

```bash
# app/frontend/.env.development
REACT_APP_API_URL=https://func-emp-api-dev.azurewebsites.net

# app/frontend/.env.production
REACT_APP_API_URL=https://func-emp-api-prod.azurewebsites.net
```

---

## 💰 Cost Comparison

| Tier | Free | Standard |
|------|------|----------|
| **Monthly Cost** | $0 | ~$9/month |
| **Bandwidth** | 100 GB/month | Unlimited |
| **Custom Domains** | 2 | Unlimited |
| **API Requests** | Included | Included |
| **Build Minutes** | 100/month | 400/month |
| **SLA** | None | 99.95% |

**This module defaults to Free tier** - Perfect for dev/staging!

---

## 🧪 Testing

```bash
# Deploy module
terraform apply

# Get deployment URL
terraform output static_web_app_url

# Get API key for manual deployment
terraform output -raw static_web_app_api_key

# Test Static Web App
curl https://<static-web-app-name>.azurestaticapps.net

# View deployment logs in Azure Portal
az staticwebapp show \
  --name swa-employee-portal-dev \
  --resource-group rg-employee-app-dev
```

---

## 🔧 Advanced Features

### Custom Domains

```hcl
# After creating Static Web App, add custom domain in Portal or via CLI
resource "azurerm_static_web_app_custom_domain" "custom" {
  static_web_app_id = module.static_web_app.static_web_app_id
  domain_name       = "employees.company.com"
  validation_type   = "dns-txt-token"
}
```

### Staging Environments

Static Web Apps automatically creates preview environments for pull requests:

- Main branch: `https://<app-name>.azurestaticapps.net`
- PR #42: `https://<app-name>-42.azurestaticapps.net`

### API Integration (Built-in Functions)

Create `api/` folder in your repository:

```javascript
// api/GetEmployees/index.js
module.exports = async function (context, req) {
    context.res = {
        body: [
            { id: 1, name: "John Doe", department: "Engineering" },
            { id: 2, name: "Jane Smith", department: "HR" }
        ]
    };
};
```

---

## 🐛 Troubleshooting

**Issue**: Build fails in GitHub Actions  
**Solution**: Check `app_location` and `output_location` in workflow YAML

**Issue**: 404 on routes (React Router)  
**Solution**: Add `staticwebapp.config.json` with navigationFallback

**Issue**: CORS errors calling Function App  
**Solution**: Configure CORS in Function App to allow Static Web App origin

**Issue**: Custom domain not validating  
**Solution**: Add TXT record to DNS provider with validation token

---

## 📘 References

- [Azure Static Web Apps Documentation](https://learn.microsoft.com/en-us/azure/static-web-apps/)
- [Terraform azurerm_static_web_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/static_web_app)
- [Configuration Reference](https://learn.microsoft.com/en-us/azure/static-web-apps/configuration)
- [SWA CLI](https://azure.github.io/static-web-apps-cli/)

---

## 👤 Maintainer

This module is part of the DTE Employee Management application infrastructure.  
Maintained by: DTE DevOps Team
