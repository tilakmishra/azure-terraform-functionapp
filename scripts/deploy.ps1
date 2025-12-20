<# 
.SYNOPSIS
    DTE Employee Management - Full Deployment Script (PowerShell)

.DESCRIPTION
    Deploys the complete infrastructure and application to Azure

.PARAMETER TfVarsFile
    The terraform variables file to use (default: dev.tfvars)

.EXAMPLE
    .\deploy.ps1 -TfVarsFile "dev.tfvars"
#>

param(
    [string]$TfVarsFile = "dev.tfvars"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "DTE Employee Management - Deployment Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$TerraformDir = $RootDir
$BackendDir = Join-Path $RootDir "app\backend"
$FrontendDir = Join-Path $RootDir "app\frontend"

Write-Host "`n📁 Root Directory: $RootDir"
Write-Host "📁 Using tfvars: $TfVarsFile"

# ============================================================================
# Step 1: Deploy Infrastructure with Terraform
# ============================================================================
Write-Host "`n🏗️  Step 1: Deploying Infrastructure..." -ForegroundColor Yellow
Write-Host "----------------------------------------"

Set-Location $TerraformDir

Write-Host "Initializing Terraform..."
terraform init

Write-Host "Planning infrastructure changes..."
terraform plan -var-file="$TfVarsFile" -out=tfplan

Write-Host "Applying infrastructure..."
terraform apply tfplan

# Get outputs
Write-Host "Getting deployment outputs..."
$FunctionAppName = terraform output -raw function_app_name 2>$null
$StaticWebAppName = terraform output -raw static_web_app_name 2>$null
$ResourceGroup = terraform output -raw resource_group_name 2>$null
$FunctionAppUrl = terraform output -raw function_app_url 2>$null

Write-Host "✅ Infrastructure deployed!" -ForegroundColor Green
Write-Host "   Function App: $FunctionAppName"
Write-Host "   Static Web App: $StaticWebAppName"
Write-Host "   Resource Group: $ResourceGroup"

# ============================================================================
# Step 2: Deploy Function App (Backend)
# ============================================================================
Write-Host "`n🐍 Step 2: Deploying Function App (Backend)..." -ForegroundColor Yellow
Write-Host "-----------------------------------------------"

Set-Location $BackendDir

Write-Host "Installing Python dependencies..."
pip install -r requirements.txt --quiet

Write-Host "Deploying to Azure Function App..."
func azure functionapp publish $FunctionAppName --python

Write-Host "✅ Backend deployed!" -ForegroundColor Green

# ============================================================================
# Step 3: Deploy Static Web App (Frontend)
# ============================================================================
Write-Host "`n⚛️  Step 3: Deploying Static Web App (Frontend)..." -ForegroundColor Yellow
Write-Host "---------------------------------------------------"

Set-Location $FrontendDir

Write-Host "Installing npm dependencies..."
npm install --silent

# Set API URL
$env:REACT_APP_API_URL = "https://$FunctionAppName.azurewebsites.net/api"

Write-Host "Building React application..."
npm run build

Write-Host "Deploying to Static Web App..."
$DeploymentToken = az staticwebapp secrets list --name $StaticWebAppName --resource-group $ResourceGroup --query "properties.apiKey" -o tsv

npx @azure/static-web-apps-cli deploy ./build --deployment-token $DeploymentToken --env production

Write-Host "✅ Frontend deployed!" -ForegroundColor Green

# ============================================================================
# Step 4: Seed Sample Data
# ============================================================================
Write-Host "`n📊 Step 4: Seeding sample data..." -ForegroundColor Yellow
Write-Host "----------------------------------"

$SampleEmployees = @(
    @{firstName="John"; lastName="Doe"; email="john.doe@example.com"; department="Engineering"; position="Senior Developer"},
    @{firstName="Jane"; lastName="Smith"; email="jane.smith@example.com"; department="Marketing"; position="Marketing Manager"},
    @{firstName="Bob"; lastName="Johnson"; email="bob.johnson@example.com"; department="Sales"; position="Sales Representative"},
    @{firstName="Alice"; lastName="Williams"; email="alice.williams@example.com"; department="HR"; position="HR Specialist"},
    @{firstName="Charlie"; lastName="Brown"; email="charlie.brown@example.com"; department="Finance"; position="Financial Analyst"}
)

foreach ($employee in $SampleEmployees) {
    $body = $employee | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri "https://$FunctionAppName.azurewebsites.net/api/employees" -Method POST -Body $body -ContentType "application/json" | Out-Null
        Write-Host "  Created: $($employee.firstName) $($employee.lastName)"
    } catch {
        Write-Host "  Warning: Could not create $($employee.firstName) $($employee.lastName)" -ForegroundColor Yellow
    }
}

Write-Host "✅ Sample data seeded!" -ForegroundColor Green

# ============================================================================
# Summary
# ============================================================================
$StaticWebAppUrl = az staticwebapp show -n $StaticWebAppName -g $ResourceGroup --query 'defaultHostname' -o tsv

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📍 URLs:"
Write-Host "   Frontend:  https://$StaticWebAppUrl" -ForegroundColor White
Write-Host "   Backend:   https://$FunctionAppName.azurewebsites.net/api" -ForegroundColor White
Write-Host "   Health:    https://$FunctionAppName.azurewebsites.net/api/health" -ForegroundColor White
Write-Host ""
Write-Host "📝 Next Steps:"
Write-Host "   1. Open the Frontend URL in your browser"
Write-Host "   2. Test the employee CRUD operations"
Write-Host "   3. Check Application Insights for monitoring"
Write-Host ""

Set-Location $RootDir
