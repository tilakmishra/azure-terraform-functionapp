#!/bin/bash
# =============================================================================
# LOCAL DEPLOYMENT SCRIPT FOR DTE EMPLOYEE MANAGEMENT
# =============================================================================
# This script deploys the Python Function App and React Frontend from your
# local machine. It works with the current DTE project structure.
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$TERRAFORM_ROOT/app/backend"
FRONTEND_DIR="$TERRAFORM_ROOT/app/frontend"

# Get resource names from arguments or use defaults
RESOURCE_GROUP="${1:-rg-emp-dev}"
FUNCTION_APP_NAME="${2:-func-emp-dev-gr0j}"
STATIC_WEB_APP_NAME="${3:-swa-dte-dev-gr0j}"

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}DTE Employee Management - Local Deployment${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo "Project Directory:   $PROJECT_DIR"
echo "Function App:        $FUNCTION_APP_NAME"
echo "Static Web App:      $STATIC_WEB_APP_NAME"
echo "Resource Group:      $RESOURCE_GROUP"
echo ""

# Verify directories exist
if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}Backend directory not found: $BACKEND_DIR${NC}"
    exit 1
fi

if [ ! -d "$FRONTEND_DIR" ]; then
    echo -e "${RED}Frontend directory not found: $FRONTEND_DIR${NC}"
    exit 1
fi

# Step 1: Deploy Backend (Function App)
echo -e "${YELLOW}[1/3] Deploying Backend to Function App...${NC}"
cd "$BACKEND_DIR"

# Install dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt -q

# Deploy to Azure
echo "Publishing to Azure Function App: $FUNCTION_APP_NAME"
func azure functionapp publish "$FUNCTION_APP_NAME" --python

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Backend deployed successfully!${NC}"
else
    echo -e "${RED}Backend deployment failed${NC}"
    exit 1
fi

# Step 2: Deploy Frontend (Static Web App)
echo ""
echo -e "${YELLOW}[2/3] Deploying Frontend to Static Web App...${NC}"
cd "$FRONTEND_DIR"

# Get the Function App URL
FUNCTION_APP_URL="https://$FUNCTION_APP_NAME.azurewebsites.net/api"
echo "Backend API URL: $FUNCTION_APP_URL"

# Set environment variable for React build
export REACT_APP_API_URL="$FUNCTION_APP_URL"

# Install dependencies and build
echo "Installing npm dependencies..."
npm install --silent

echo "Building React app..."
npm run build

# Get deployment token
echo "Getting Static Web App deployment token..."
TOKEN=$(az staticwebapp secrets list --name "$STATIC_WEB_APP_NAME" --resource-group "$RESOURCE_GROUP" --query "properties.apiKey" -o tsv)

if [ -z "$TOKEN" ]; then
    echo -e "${RED}Could not get Static Web App deployment token${NC}"
    exit 1
fi

# Deploy using SWA CLI
echo "Deploying to Static Web App: $STATIC_WEB_APP_NAME"
npx @azure/static-web-apps-cli deploy ./build --deployment-token "$TOKEN"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Frontend deployed successfully!${NC}"
else
    echo -e "${RED}Frontend deployment failed${NC}"
    exit 1
fi

# Step 3: Seed Sample Data
echo ""
echo -e "${YELLOW}[3/3] Seeding sample data to Cosmos DB...${NC}"

API_URL="https://$FUNCTION_APP_NAME.azurewebsites.net/api"

# Wait for function app to warm up
echo "Waiting for Function App to be ready..."
sleep 10

# Sample employees
EMPLOYEES=(
  '{"firstName":"John","lastName":"Doe","email":"john.doe@company.com","department":"Engineering","position":"Senior Developer"}'
  '{"firstName":"Jane","lastName":"Smith","email":"jane.smith@company.com","department":"HR","position":"HR Manager"}'
  '{"firstName":"Bob","lastName":"Johnson","email":"bob.j@company.com","department":"Engineering","position":"DevOps Engineer"}'
  '{"firstName":"Alice","lastName":"Williams","email":"alice.w@company.com","department":"Marketing","position":"Marketing Manager"}'
  '{"firstName":"Charlie","lastName":"Brown","email":"charlie.b@company.com","department":"Sales","position":"Sales Representative"}'
)

for employee in "${EMPLOYEES[@]}"; do
  curl -s -X POST "$API_URL/employees" \
    -H "Content-Type: application/json" \
    -d "$employee" > /dev/null
  echo "  Created: $(echo "$employee" | grep -o '"firstName":"[^"]*' | cut -d'"' -f4) $(echo "$employee" | grep -o '"lastName":"[^"]*' | cut -d'"' -f4)"
done

echo -e "${GREEN}✓ Sample data seeded!${NC}"

# Done!
echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${GREEN}🎉 DEPLOYMENT COMPLETE!${NC}"
echo -e "${CYAN}============================================${NC}"

# Get Static Web App URL
SWA_URL=$(az staticwebapp show --name "$STATIC_WEB_APP_NAME" --resource-group "$RESOURCE_GROUP" --query "defaultHostname" -o tsv)

echo ""
echo -e "${CYAN}📍 URLs:${NC}"
echo -e "   Frontend:  ${CYAN}https://$SWA_URL${NC}"
echo -e "   Backend:   ${CYAN}https://$FUNCTION_APP_NAME.azurewebsites.net/api${NC}"
echo -e "   Health:    ${CYAN}https://$FUNCTION_APP_NAME.azurewebsites.net/api/health${NC}"
echo ""
echo -e "${CYAN}📝 Next Steps:${NC}"
echo "   1. Open the Frontend URL in your browser"
echo "   2. Test the employee CRUD operations"
echo "   3. Check Application Insights for monitoring"
echo ""
