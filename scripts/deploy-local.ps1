# DTE EMPLOYEE MANAGEMENT - LOCAL DEPLOYMENT SCRIPT (WINDOWS)
# This script deploys the Python Function App and React Frontend from your local machine.

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "rg-emp-dev",
    
    [Parameter(Mandatory=$false)]
    [string]$FunctionAppName = "func-emp-dev-gr0j",
    
    [Parameter(Mandatory=$false)]
    [string]$StaticWebAppName = "swa-dte-dev-gr0j"
)

$ErrorActionPreference = "Stop"

# Get script directory and terraform root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformRoot = Split-Path -Parent $ScriptDir
$BackendDir = Join-Path $TerraformRoot "app" "backend"
$FrontendDir = Join-Path $TerraformRoot "app" "frontend"

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "DTE Employee Management - Local Deployment" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Terraform Root:    $TerraformRoot"
Write-Host "Function App:      $FunctionAppName"
Write-Host "Static Web App:    $StaticWebAppName"
Write-Host "Resource Group:    $ResourceGroup"
Write-Host ""

# Verify directories exist
if (-not (Test-Path $BackendDir)) {
    Write-Host "ERROR: Backend directory not found: $BackendDir" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $FrontendDir)) {
    Write-Host "ERROR: Frontend directory not found: $FrontendDir" -ForegroundColor Red
    exit 1
}

# Step 1: Deploy Backend (Function App)
Write-Host "[1/3] Deploying Backend to Function App..." -ForegroundColor Yellow

Push-Location $BackendDir
try {
    Write-Host "Installing Python dependencies..."
    pip install -r requirements.txt -q
    
    Write-Host "Publishing to Azure Function App: $FunctionAppName"
    func azure functionapp publish $FunctionAppName --python
    
    if ($LASTEXITCODE -ne 0) {
        throw "Function App deployment failed"
    }
    Write-Host "[OK] Backend deployed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Backend deployment failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
finally {
    Pop-Location
}

# Step 2: Deploy Frontend (Static Web App)
Write-Host "`n[2/3] Deploying Frontend to Static Web App..." -ForegroundColor Yellow

Push-Location $FrontendDir
try {
    $FunctionAppUrl = "https://$FunctionAppName.azurewebsites.net/api"
    Write-Host "Backend API URL: $FunctionAppUrl"
    
    $env:REACT_APP_API_URL = $FunctionAppUrl
    
    Write-Host "Installing npm dependencies..."
    npm install --silent
    
    Write-Host "Building React app..."
    npm run build
    
    Write-Host "Getting Static Web App deployment token..."
    $Token = az staticwebapp secrets list --name $StaticWebAppName --resource-group $ResourceGroup --query "properties.apiKey" -o tsv
    
    if ([string]::IsNullOrEmpty($Token)) {
        throw "Could not get Static Web App deployment token"
    }
    
    Write-Host "Deploying to Static Web App: $StaticWebAppName"
    npx @azure/static-web-apps-cli deploy ./build --deployment-token $Token
    
    Write-Host "[OK] Frontend deployed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Frontend deployment failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
finally {
    Pop-Location
}

# Step 3: Seed Sample Data
Write-Host "`n[3/3] Seeding sample data to Cosmos DB..." -ForegroundColor Yellow

$ApiUrl = "https://$FunctionAppName.azurewebsites.net/api"

Write-Host "Waiting for Function App to be ready..."
Start-Sleep -Seconds 10

$Employees = @(
    @{firstName="John"; lastName="Doe"; email="john.doe@company.com"; department="Engineering"; position="Senior Developer"},
    @{firstName="Jane"; lastName="Smith"; email="jane.smith@company.com"; department="HR"; position="HR Manager"},
    @{firstName="Bob"; lastName="Johnson"; email="bob.j@company.com"; department="Engineering"; position="DevOps Engineer"},
    @{firstName="Alice"; lastName="Williams"; email="alice.w@company.com"; department="Marketing"; position="Marketing Manager"},
    @{firstName="Charlie"; lastName="Brown"; email="charlie.b@company.com"; department="Sales"; position="Sales Representative"}
)

foreach ($employee in $Employees) {
    $Body = $employee | ConvertTo-Json
    Invoke-RestMethod -Uri "$ApiUrl/employees" -Method Post -ContentType "application/json" -Body $Body | Out-Null
    Write-Host "  Created: $($employee.firstName) $($employee.lastName)"
}

Write-Host "[OK] Sample data seeded!" -ForegroundColor Green

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan

$SwaUrl = az staticwebapp show --name $StaticWebAppName --resource-group $ResourceGroup --query "defaultHostname" -o tsv

Write-Host ""
Write-Host "URLs:" -ForegroundColor Cyan
Write-Host "   Frontend:  https://$SwaUrl" -ForegroundColor White
Write-Host "   Backend:   https://$FunctionAppName.azurewebsites.net/api" -ForegroundColor White
Write-Host "   Health:    https://$FunctionAppName.azurewebsites.net/api/health" -ForegroundColor White

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Open the Frontend URL in your browser"
Write-Host "   2. Test the employee CRUD operations"
Write-Host "   3. Check Application Insights for monitoring"
Write-Host ""
