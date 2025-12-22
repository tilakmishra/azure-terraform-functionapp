# =============================================================================
# OPTION 2: AZURE CLOUD SHELL DEPLOYMENT
# =============================================================================
# Run this script from Azure Cloud Shell (portal.azure.com -> Cloud Shell)
# This bypasses private endpoint restrictions by running inside Azure's network
# =============================================================================

#!/bin/bash
set -e

# Configuration - UPDATE THESE
RESOURCE_GROUP="rg-emp-dev"
FUNCTION_APP_NAME="func-emp-dev-gr0j"
STATIC_WEB_APP_NAME="swa-dte-dev-gr0j"
REPO_URL="https://github.com/tilakmishra/azure-terraform-webapp.git"

echo "============================================"
echo "OPTION 2: Azure Cloud Shell Deployment"
echo "============================================"

# Clone the repo
echo "[1/5] Cloning repository..."
git clone $REPO_URL deployment-temp
cd deployment-temp/terraform

# Deploy Backend
echo "[2/5] Deploying Backend (Python Function App)..."
cd app/backend
pip install -r requirements.txt --quiet
func azure functionapp publish $FUNCTION_APP_NAME --python
cd ../..

# Deploy Frontend
echo "[3/5] Building Frontend (React)..."
cd app/frontend
export REACT_APP_API_URL="https://$FUNCTION_APP_NAME.azurewebsites.net/api"
npm install --quiet
npm run build

echo "[4/5] Deploying Frontend to Static Web App..."
DEPLOYMENT_TOKEN=$(az staticwebapp secrets list --name $STATIC_WEB_APP_NAME --resource-group $RESOURCE_GROUP --query "properties.apiKey" -o tsv)
npx @azure/static-web-apps-cli deploy ./build --deployment-token $DEPLOYMENT_TOKEN

# Seed Data
echo "[5/5] Seeding sample data..."
API_URL="https://$FUNCTION_APP_NAME.azurewebsites.net/api"

curl -X POST "$API_URL/employees" -H "Content-Type: application/json" \
    -d '{"firstName":"John","lastName":"Doe","email":"john.doe@company.com","department":"Engineering","position":"Senior Developer"}'

curl -X POST "$API_URL/employees" -H "Content-Type: application/json" \
    -d '{"firstName":"Jane","lastName":"Smith","email":"jane.smith@company.com","department":"HR","position":"HR Manager"}'

curl -X POST "$API_URL/employees" -H "Content-Type: application/json" \
    -d '{"firstName":"Bob","lastName":"Johnson","email":"bob.j@company.com","department":"Engineering","position":"DevOps Engineer"}'

# Cleanup
cd ../../..
rm -rf deployment-temp

echo "============================================"
echo "DEPLOYMENT COMPLETE!"
echo "============================================"
SWA_URL=$(az staticwebapp show --name $STATIC_WEB_APP_NAME --resource-group $RESOURCE_GROUP --query "defaultHostname" -o tsv)
echo "Your app is live at: https://$SWA_URL"
echo "API endpoint: https://$FUNCTION_APP_NAME.azurewebsites.net/api/employees"
