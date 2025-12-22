# Deployment Checklist - Employee Management App

## ✅ Pre-Deployment Checklist

### 1. Azure Service Principal Setup
```bash
# Create service principal for GitHub Actions
az ad sp create-for-rbac --name "github-actions-dte-deploy" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --sdk-auth

# Copy the JSON output - you'll need this for GitHub Secrets
```

**Expected Output:**
```json
{
  "clientId": "xxxxx",
  "clientSecret": "xxxxx",
  "subscriptionId": "xxxxx",
  "tenantId": "xxxxx",
  ...
}
```

### 2. GitHub Repository Secrets
Navigate to: **GitHub Repo → Settings → Secrets and variables → Actions → New repository secret**

Add these secrets:

| Secret Name | Value | How to Get |
|------------|-------|------------|
| `AZURE_CREDENTIALS` | Entire JSON from step 1 | Service principal JSON output |
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | Will be created by Terraform | Leave blank initially - Terraform creates this |

> **Note:** The Static Web App deployment token will be automatically created by Terraform. You'll update this secret after the first Terraform deployment.

### 3. Verify Your Files Structure
```
azure/DTE/terraform/
├── .gitignore ✅ (excludes documentation)
├── .github/
│   └── workflows/
│       └── deploy.yml ✅ (workflow ready)
├── app/
│   ├── backend/
│   │   ├── function_app.py ✅
│   │   ├── requirements.txt ✅
│   │   └── host.json ✅
│   └── frontend/
│       ├── src/ ✅
│       ├── package.json ✅
│       └── public/ ✅
├── modules/ ✅
├── main.tf ✅
├── rbac.tf ✅ (with Cosmos DB + Storage RBAC)
├── outputs.tf ✅ (with principal_id, URLs)
└── dev.tfvars ✅
```

---

## 🚀 Deployment Steps

### Step 1: Initialize Git Repository (if not done)
```bash
cd C:\Users\tilak\OneDrive\Documents\TerraformCode\azure\DTE\terraform

# Initialize git
git init

# Add remote (replace with your GitHub repo URL)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
```

### Step 2: Stage and Commit Code
```bash
# Check what will be committed (should exclude all .md docs)
git status

# Add all files
git add .

# Commit
git commit -m "Initial deployment: Infrastructure + Backend + Frontend"

# Push to GitHub
git push -u origin main
```

### Step 3: Get Static Web App Deployment Token (After First Deploy)
After the first **manual Terraform deployment**, get the deployment token:

```bash
# Option 1: From Terraform output
cd azure/DTE/terraform
terraform output -raw static_web_app_deployment_token

# Option 2: From Azure Portal
# Azure Portal → Static Web Apps → Your App → Manage Deployment Token → Copy
```

Then add it to GitHub Secrets:
- Secret Name: `AZURE_STATIC_WEB_APPS_API_TOKEN`
- Value: Paste the token

### Step 4: Trigger GitHub Actions Workflow
**Option A: Via GitHub UI**
1. Go to GitHub → Your Repo → **Actions** tab
2. Click **Deploy Infrastructure and Application**
3. Click **Run workflow** → Select `main` branch → **Run workflow**

**Option B: Via Git Push (currently disabled)**
The workflow is set to `workflow_dispatch` (manual only). To enable auto-deploy on push:
```yaml
# Edit .github/workflows/deploy.yml
on:
  push:
    branches: [main]
  workflow_dispatch:
```

### Step 5: Monitor Deployment (40-50 minutes)
Watch the workflow progress:
1. **Infrastructure (15-20 min)**: Terraform provisions all Azure resources
2. **Deploy Backend (3-5 min)**: Python Function App deployment
3. **Deploy Frontend (5-8 min)**: React app build and deploy
4. **Verify Deployment (1-2 min)**: Health checks and output URLs

### Step 6: Get Deployment URLs
After successful deployment, check the **Verify Deployment** job output:

```
Frontend URL: https://YOUR_STATIC_WEB_APP.azurestaticapps.net
Backend API: https://YOUR_FUNCTION_APP.azurewebsites.net
Health Check: https://YOUR_FUNCTION_APP.azurewebsites.net/api/health
```

---

## 🧪 Testing End-to-End Integration

### Test 1: Health Check (API is alive)
```bash
curl https://YOUR_FUNCTION_APP.azurewebsites.net/api/health
```

**Expected:**
```json
{"status": "healthy", "timestamp": "2025-12-21T..."}
```

### Test 2: Create Employee (Python → Cosmos DB)
```bash
curl -X POST https://YOUR_FUNCTION_APP.azurewebsites.net/api/employees \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "department": "Engineering",
    "position": "Software Engineer"
  }'
```

**Expected:**
```json
{
  "id": "uuid-here",
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "department": "Engineering",
  "position": "Software Engineer",
  "createdAt": "2025-12-21T..."
}
```

### Test 3: Get All Employees (Cosmos DB → Python → React)
```bash
curl https://YOUR_FUNCTION_APP.azurewebsites.net/api/employees
```

**Expected:**
```json
{
  "employees": [
    {
      "id": "uuid-here",
      "firstName": "John",
      ...
    }
  ],
  "count": 1
}
```

### Test 4: Frontend Integration (React → API → Cosmos DB)
1. Open: `https://YOUR_STATIC_WEB_APP.azurestaticapps.net`
2. Should see Employee Management UI
3. Click **Add Employee** → Fill form → Submit
4. Should see new employee in the list
5. Verify data persists after page refresh (stored in Cosmos DB)

---

## ❌ Troubleshooting Common Issues

### Issue 1: GitHub Actions - Terraform Init Failed
**Error:** `Error: Failed to get existing workspaces: storage account not found`

**Solution:**
```bash
# Run Terraform manually first to create backend storage
cd azure/DTE/terraform
terraform init
terraform apply -var-file="dev.tfvars"

# Then retry GitHub Actions
```

### Issue 2: Function App Returns 403 (Forbidden)
**Error:** `403 Forbidden when accessing Cosmos DB`

**Diagnosis:**
```bash
# Check RBAC role assignments
az role assignment list --assignee YOUR_FUNCTION_APP_PRINCIPAL_ID

# Should see:
# - Cosmos DB SQL Data Contributor
# - Storage Blob Data Reader
# - Key Vault Secrets User
```

**Solution:** Wait 5-10 minutes for RBAC propagation, or manually assign:
```bash
az cosmosdb sql role assignment create \
  --account-name YOUR_COSMOS_ACCOUNT \
  --resource-group YOUR_RG \
  --scope "/" \
  --principal-id YOUR_FUNCTION_APP_PRINCIPAL_ID \
  --role-definition-id 00000000-0000-0000-0000-000000000002
```

### Issue 3: Static Web App - API Not Found
**Error:** Frontend shows "Network Error" or "ERR_NAME_NOT_RESOLVED"

**Diagnosis:**
```bash
# Check if React has correct API URL
# Open browser console: Settings → Application → Environment Variables
# Should show: REACT_APP_API_URL = https://YOUR_FUNCTION_APP.azurewebsites.net/api
```

**Solution:** Rebuild frontend with correct environment variable:
```bash
# GitHub Actions should auto-inject this, but if manual:
cd azure/DTE/terraform/app/frontend
REACT_APP_API_URL=https://YOUR_FUNCTION_APP.azurewebsites.net/api npm run build
```

### Issue 4: CORS Errors in Browser
**Error:** `Access to fetch at '...' has been blocked by CORS policy`

**Diagnosis:**
```bash
# Check Function App CORS settings
az functionapp cors show --name YOUR_FUNCTION_APP --resource-group YOUR_RG
```

**Solution:** Function App module should already have CORS configured for Static Web App. If not:
```bash
az functionapp cors add \
  --name YOUR_FUNCTION_APP \
  --resource-group YOUR_RG \
  --allowed-origins https://YOUR_STATIC_WEB_APP.azurestaticapps.net
```

---

## ✅ Success Criteria

Your deployment is **SUCCESSFUL** when:

- ✅ GitHub Actions workflow completes all 4 jobs without errors
- ✅ Health endpoint returns `{"status": "healthy"}`
- ✅ POST `/api/employees` creates data in Cosmos DB
- ✅ GET `/api/employees` retrieves data from Cosmos DB
- ✅ Frontend UI loads and displays employee list
- ✅ Adding employee via UI persists to Cosmos DB
- ✅ No console errors in browser (check F12 → Console)
- ✅ Network tab shows 200 OK responses (F12 → Network)

---

## 📞 Next Steps After Deployment

1. **Verify RBAC Permissions**
   ```bash
   # Check Function App identity has correct roles
   az role assignment list --all --assignee YOUR_PRINCIPAL_ID --output table
   ```

2. **Test All CRUD Operations**
   - Create employee
   - Read employees
   - Update employee
   - Delete employee

3. **Monitor Application Insights**
   ```bash
   # View logs
   az monitor app-insights query \
     --app YOUR_APP_INSIGHTS \
     --analytics-query "requests | where timestamp > ago(1h)"
   ```

4. **Share URLs with Client**
   - Frontend: `https://YOUR_STATIC_WEB_APP.azurestaticapps.net`
   - API Docs: Include endpoint list from deployment output

---

**Deployment Time:** ~40-50 minutes  
**Manual Steps Required:** 3 (Service Principal, GitHub Secrets, Trigger Workflow)  
**Automated Steps:** 4 (Infrastructure, Backend, Frontend, Verification)
