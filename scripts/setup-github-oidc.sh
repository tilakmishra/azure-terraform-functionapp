#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# GitHub OIDC Setup Script for Azure Terraform Deployments
# ═══════════════════════════════════════════════════════════════════════════════
# 
# This script sets up GitHub OIDC (OpenID Connect) federation with Azure,
# eliminating the need to store Service Principal credentials in GitHub Secrets.
#
# Security Benefits:
# ✅ No long-lived credentials stored in GitHub
# ✅ Time-limited OIDC tokens (valid for 1 hour)
# ✅ Full audit trail in Azure Activity Log
# ✅ Can be revoked immediately
#
# Prerequisites:
# - Azure CLI installed and authenticated
# - GitHub CLI (gh) installed and authenticated (optional)
# - Appropriate Azure permissions (to create app registrations)
#
# Usage:
#   ./setup-github-oidc.sh \
#     --github-org YOUR_ORG \
#     --github-repo YOUR_REPO \
#     --azure-subscription YOUR_SUBSCRIPTION_ID
#
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
GITHUB_ORG=""
GITHUB_REPO=""
AZURE_SUBSCRIPTION=""
APP_NAME=""
LOCATION="eastus2"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --github-org)
      GITHUB_ORG="$2"
      shift 2
      ;;
    --github-repo)
      GITHUB_REPO="$2"
      shift 2
      ;;
    --azure-subscription)
      AZURE_SUBSCRIPTION="$2"
      shift 2
      ;;
    --location)
      LOCATION="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate inputs
if [ -z "$GITHUB_ORG" ] || [ -z "$GITHUB_REPO" ] || [ -z "$AZURE_SUBSCRIPTION" ]; then
  echo -e "${RED}Error: Missing required parameters${NC}"
  echo "Usage: $0 --github-org ORG --github-repo REPO --azure-subscription SUB_ID"
  exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}GitHub OIDC Setup for Azure${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  GitHub Org:           $GITHUB_ORG"
echo "  GitHub Repo:          $GITHUB_REPO"
echo "  Azure Subscription:   $AZURE_SUBSCRIPTION"
echo ""

# Set subscription
echo -e "${YELLOW}Step 1: Setting Azure subscription...${NC}"
az account set --subscription "$AZURE_SUBSCRIPTION"
TENANT_ID=$(az account show --query tenantId -o tsv)
echo -e "${GREEN}✓ Subscription set${NC}"
echo "  Tenant ID: $TENANT_ID"
echo ""

# Create app registration
APP_NAME="github-oidc-${GITHUB_REPO}"
echo -e "${YELLOW}Step 2: Creating Azure AD App Registration...${NC}"
APP_ID=$(az ad app create \
  --display-name "$APP_NAME" \
  --query appId \
  -o tsv)
echo -e "${GREEN}✓ App Registration created${NC}"
echo "  App ID: $APP_ID"
echo ""

# Create service principal
echo -e "${YELLOW}Step 3: Creating Service Principal...${NC}"
PRINCIPAL_ID=$(az ad sp create \
  --id "$APP_ID" \
  --query id \
  -o tsv)
echo -e "${GREEN}✓ Service Principal created${NC}"
echo "  Principal ID: $PRINCIPAL_ID"
echo ""

# Add OIDC federation credential
echo -e "${YELLOW}Step 4: Creating OIDC Federation Credential...${NC}"

# Create credential for main branch
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters @- <<EOF
{
  "name": "github-${GITHUB_REPO}-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF
echo -e "${GREEN}✓ OIDC credential created for main branch${NC}"

# Create credential for workflow_dispatch
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters @- <<EOF
{
  "name": "github-${GITHUB_REPO}-workflow-dispatch",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${GITHUB_ORG}/${GITHUB_REPO}:environment:terraform",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF
echo -e "${GREEN}✓ OIDC credential created for workflow_dispatch${NC}"
echo ""

# Assign roles
echo -e "${YELLOW}Step 5: Assigning Azure Role (Contributor)...${NC}"
az role assignment create \
  --role Contributor \
  --assignee "$APP_ID" \
  --scope "/subscriptions/$AZURE_SUBSCRIPTION" \
  > /dev/null
echo -e "${GREEN}✓ Contributor role assigned${NC}"
echo "  (This is for demonstration. Restrict to specific resource groups in production!)"
echo ""

# Display configuration
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}GitHub OIDC Setup Complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Store these values in GitHub (Settings → Secrets → Actions):${NC}"
echo ""
echo "AZURE_CLIENT_ID:"
echo "  $APP_ID"
echo ""
echo "AZURE_TENANT_ID:"
echo "  $TENANT_ID"
echo ""
echo "AZURE_SUBSCRIPTION_ID:"
echo "  $AZURE_SUBSCRIPTION"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Only store AZURE_CLIENT_ID as a secret.${NC}"
echo "   AZURE_TENANT_ID and AZURE_SUBSCRIPTION_ID are public values."
echo ""

# Create environment for terraform
echo -e "${YELLOW}Optional: Create GitHub environment for Terraform...${NC}"
echo ""
echo "  1. Go to: https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/settings/environments"
echo "  2. Click 'New environment' and name it 'terraform'"
echo "  3. Add these environment secrets:"
echo "     - AZURE_CLIENT_ID = $APP_ID"
echo "     - AZURE_TENANT_ID = $TENANT_ID"
echo "     - AZURE_SUBSCRIPTION_ID = $AZURE_SUBSCRIPTION"
echo ""

# Bootstrap terraform state
echo -e "${YELLOW}Step 6: Creating Terraform State Backend...${NC}"

RG_NAME="rg-terraform-state"
STORAGE_NAME="tfstateemp"
CONTAINER_NAME="tfstate"

# Create resource group
az group create \
  --name "$RG_NAME" \
  --location "$LOCATION" \
  > /dev/null
echo -e "${GREEN}✓ Resource group created: $RG_NAME${NC}"

# Create storage account
az storage account create \
  --resource-group "$RG_NAME" \
  --name "$STORAGE_NAME" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --https-only true \
  --public-network-access Disabled \
  --default-action Deny \
  > /dev/null
echo -e "${GREEN}✓ Storage account created: $STORAGE_NAME${NC}"

# Create container
az storage container create \
  --account-name "$STORAGE_NAME" \
  --name "$CONTAINER_NAME" \
  > /dev/null
echo -e "${GREEN}✓ Container created: $CONTAINER_NAME${NC}"

# Grant service principal access to storage account
STORAGE_ID=$(az storage account show \
  --resource-group "$RG_NAME" \
  --name "$STORAGE_NAME" \
  --query id \
  -o tsv)

az role assignment create \
  --role "Storage Blob Data Owner" \
  --assignee "$APP_ID" \
  --scope "$STORAGE_ID" \
  > /dev/null
echo -e "${GREEN}✓ Service Principal granted Storage Blob Data Owner role${NC}"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}All Setup Complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Add GitHub Secrets (see values above)"
echo "  2. Update GitHub Actions workflows to use OIDC"
echo "  3. Test with: gh workflow run deploy.yml"
echo ""
echo -e "${YELLOW}Verify setup:${NC}"
echo "  az role assignment list --assignee '$APP_ID'"
echo ""
