#!/bin/bash
# =============================================================================
# OPTION 1: SIMPLEST DEPLOYMENT (Local Machine)
# =============================================================================
# This script deploys the app from your local machine.
# Works because public_network_access_enabled = true on Function App
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -lt 3 ]; then
    echo -e "${RED}Usage: $0 <FunctionAppName> <StaticWebAppName> <ResourceGroupName>${NC}"
    echo ""
    echo "Example:"
    echo "  $0 func-dte-dev-eastus swa-dte-dev-eastus rg-dte-dev-eastus"
    echo ""
    echo "Get values from terraform output:"
    echo "  terraform output"
    exit 1
fi

FUNCTION_APP_NAME=$1
STATIC_WEB_APP_NAME=$2
RESOURCE_GROUP_NAME=$3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}OPTION 1: Simple Local Deployment${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo "Function App:    $FUNCTION_APP_NAME"
echo "Static Web App:  $STATIC_WEB_APP_NAME"
echo "Resource Group:  $RESOURCE_GROUP_NAME"
echo ""

# Step 1: Deploy Backend (Function App)
echo -e "${YELLOW}[1/3] Deploying Backend to Function App...${NC}"
BACKEND_DIR="$ROOT_DIR/app/backend"

if [ -d "$BACKEND_DIR" ]; then
    cd "$BACKEND_DIR"
    
    # Install dependencies locally first
    echo "Installing Python dependencies..."
    pip install -r requirements.txt -q
    
    # Deploy to Azure
    echo "Publishing to Azure Function App: $FUNCTION_APP_NAME"
    func azure functionapp publish "$FUNCTION_APP_NAME" --python
    
    echo -e "${GREEN}✓ Backend deployed successfully!${NC}"
else
    echo -e "${RED}Backend directory not found: $BACKEND_DIR${NC}"
    exit 1
fi

# Step 2: Deploy Frontend (Static Web App)
echo ""
echo -e "${YELLOW}[2/3] Deploying Frontend to Static Web App...${NC}"
FRONTEND_DIR="$ROOT_DIR/app/frontend"

if [ -d "$FRONTEND_DIR" ]; then
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
    TOKEN=$(az staticwebapp secrets list --name "$STATIC_WEB_APP_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "properties.apiKey" -o tsv)
    
    if [ -z "$TOKEN" ]; then
        echo -e "${RED}Could not get Static Web App deployment token${NC}"
        exit 1
    fi
    
    # Deploy using SWA CLI
    echo "Deploying to Static Web App: $STATIC_WEB_APP_NAME"
    npx @azure/static-web-apps-cli deploy ./build --deployment-token "$TOKEN"
    
    echo -e "${GREEN}✓ Frontend deployed successfully!${NC}"
else
    echo -e "${RED}Frontend directory not found: $FRONTEND_DIR${NC}"
    exit 1
fi

# Step 3: Seed Sample Data
echo ""
echo -e "${YELLOW}[3/3] Seeding sample data to Cosmos DB...${NC}"

API_URL="https://$FUNCTION_APP_NAME.azurewebsites.net/api"

# Wait for function app to warm up
echo "Waiting for Function App to be ready..."
sleep 10

# Seed sample employees
EMPLOYEES=(
    '{"firstName":"John","lastName":"Doe","email":"john.doe@company.com","department":"Engineering","position":"Senior Developer"}'
    '{"firstName":"Jane","lastName":"Smith","email":"jane.smith@company.com","department":"HR","position":"HR Manager"}'
    '{"firstName":"Bob","lastName":"Johnson","email":"bob.j@company.com","department":"Engineering","position":"DevOps Engineer"}'
    '{"firstName":"Alice","lastName":"Williams","email":"alice.w@company.com","department":"Finance","position":"Financial Analyst"}'
    '{"firstName":"Charlie","lastName":"Brown","email":"charlie.b@company.com","department":"Sales","position":"Sales Manager"}'
)

for emp in "${EMPLOYEES[@]}"; do
    # Extract name for display
    name=$(echo "$emp" | grep -o '"firstName":"[^"]*"' | cut -d'"' -f4)
    lastname=$(echo "$emp" | grep -o '"lastName":"[^"]*"' | cut -d'"' -f4)
    
    response=$(curl -s -w "%{http_code}" -o /dev/null -X POST "$API_URL/employees" \
        -H "Content-Type: application/json" \
        -d "$emp")
    
    if [ "$response" = "200" ] || [ "$response" = "201" ]; then
        echo -e "  Added: $name $lastname"
    else
        echo -e "  ${YELLOW}Warning: Could not add $name $lastname (may already exist)${NC}"
    fi
done

echo -e "${GREEN}✓ Sample data seeded!${NC}"

# Done!
echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${GREEN}DEPLOYMENT COMPLETE!${NC}"
echo -e "${CYAN}============================================${NC}"

# Get Static Web App URL
SWA_URL=$(az staticwebapp show --name "$STATIC_WEB_APP_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "defaultHostname" -o tsv)

echo ""
echo -e "${CYAN}Your app is live at: https://$SWA_URL${NC}"
echo -e "${CYAN}API endpoint: https://$FUNCTION_APP_NAME.azurewebsites.net/api/employees${NC}"
