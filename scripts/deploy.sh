#!/bin/bash
# ============================================================================
# DTE Employee Management - Full Deployment Script
# ============================================================================
# This script deploys the complete infrastructure and application
# Prerequisites: Azure CLI, Terraform, Node.js, Python 3.11+, Azure Functions Core Tools
# ============================================================================

set -e

echo "============================================"
echo "DTE Employee Management - Deployment Script"
echo "============================================"

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$ROOT_DIR"
BACKEND_DIR="$ROOT_DIR/app/backend"
FRONTEND_DIR="$ROOT_DIR/app/frontend"
TFVARS_FILE="${1:-dev.tfvars}"

echo "📁 Root Directory: $ROOT_DIR"
echo "📁 Using tfvars: $TFVARS_FILE"

# ============================================================================
# Step 1: Deploy Infrastructure with Terraform
# ============================================================================
echo ""
echo "🏗️  Step 1: Deploying Infrastructure..."
echo "----------------------------------------"

cd "$TERRAFORM_DIR"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Plan and Apply
echo "Planning infrastructure changes..."
terraform plan -var-file="$TFVARS_FILE" -out=tfplan

echo "Applying infrastructure..."
terraform apply tfplan

# Get outputs
echo "Getting deployment outputs..."
FUNCTION_APP_NAME=$(terraform output -raw function_app_name 2>/dev/null || echo "")
STATIC_WEB_APP_NAME=$(terraform output -raw static_web_app_name 2>/dev/null || echo "")
RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null || echo "")
FUNCTION_APP_URL=$(terraform output -raw function_app_url 2>/dev/null || echo "")

echo "✅ Infrastructure deployed!"
echo "   Function App: $FUNCTION_APP_NAME"
echo "   Static Web App: $STATIC_WEB_APP_NAME"
echo "   Resource Group: $RESOURCE_GROUP"

# ============================================================================
# Step 2: Deploy Function App (Backend)
# ============================================================================
echo ""
echo "🐍 Step 2: Deploying Function App (Backend)..."
echo "-----------------------------------------------"

cd "$BACKEND_DIR"

# Install dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt --quiet

# Deploy to Azure
echo "Deploying to Azure Function App..."
func azure functionapp publish "$FUNCTION_APP_NAME" --python

echo "✅ Backend deployed!"

# ============================================================================
# Step 3: Deploy Static Web App (Frontend)
# ============================================================================
echo ""
echo "⚛️  Step 3: Deploying Static Web App (Frontend)..."
echo "---------------------------------------------------"

cd "$FRONTEND_DIR"

# Install dependencies
echo "Installing npm dependencies..."
npm install --silent

# Set API URL environment variable
export REACT_APP_API_URL="https://${FUNCTION_APP_NAME}.azurewebsites.net/api"

# Build
echo "Building React application..."
npm run build

# Deploy using SWA CLI
echo "Deploying to Static Web App..."
DEPLOYMENT_TOKEN=$(az staticwebapp secrets list --name "$STATIC_WEB_APP_NAME" --resource-group "$RESOURCE_GROUP" --query "properties.apiKey" -o tsv)

npx @azure/static-web-apps-cli deploy ./build \
  --deployment-token "$DEPLOYMENT_TOKEN" \
  --env production

echo "✅ Frontend deployed!"

# ============================================================================
# Step 4: Seed Sample Data
# ============================================================================
echo ""
echo "📊 Step 4: Seeding sample data..."
echo "----------------------------------"

# Call the API to create sample employees
SAMPLE_EMPLOYEES='[
  {"firstName":"John","lastName":"Doe","email":"john.doe@example.com","department":"Engineering","position":"Senior Developer"},
  {"firstName":"Jane","lastName":"Smith","email":"jane.smith@example.com","department":"Marketing","position":"Marketing Manager"},
  {"firstName":"Bob","lastName":"Johnson","email":"bob.johnson@example.com","department":"Sales","position":"Sales Representative"},
  {"firstName":"Alice","lastName":"Williams","email":"alice.williams@example.com","department":"HR","position":"HR Specialist"},
  {"firstName":"Charlie","lastName":"Brown","email":"charlie.brown@example.com","department":"Finance","position":"Financial Analyst"}
]'

echo "$SAMPLE_EMPLOYEES" | jq -c '.[]' | while read employee; do
  curl -s -X POST "https://${FUNCTION_APP_NAME}.azurewebsites.net/api/employees" \
    -H "Content-Type: application/json" \
    -d "$employee" > /dev/null
  echo "  Created: $(echo $employee | jq -r '.firstName + " " + .lastName')"
done

echo "✅ Sample data seeded!"

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "============================================"
echo "🎉 Deployment Complete!"
echo "============================================"
echo ""
echo "📍 URLs:"
echo "   Frontend:  https://$(az staticwebapp show -n $STATIC_WEB_APP_NAME -g $RESOURCE_GROUP --query 'defaultHostname' -o tsv)"
echo "   Backend:   https://${FUNCTION_APP_NAME}.azurewebsites.net/api"
echo "   Health:    https://${FUNCTION_APP_NAME}.azurewebsites.net/api/health"
echo ""
echo "📝 Next Steps:"
echo "   1. Open the Frontend URL in your browser"
echo "   2. Test the employee CRUD operations"
echo "   3. Check Application Insights for monitoring"
echo ""
