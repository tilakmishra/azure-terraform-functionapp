# =============================================================================
# OPTION 1: SIMPLEST DEPLOYMENT (Local Machine)
# =============================================================================
# This script deploys the app from your local machine.
# Works because public_network_access_enabled = true on Function App
# =============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$StaticWebAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "OPTION 1: Simple Local Deployment" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

# Step 1: Deploy Backend (Function App)
Write-Host "`n[1/3] Deploying Backend to Function App..." -ForegroundColor Yellow
$BackendDir = Join-Path $RootDir "app\backend"

if (Test-Path $BackendDir) {
    Push-Location $BackendDir
    try {
        # Install dependencies locally first
        Write-Host "Installing Python dependencies..."
        pip install -r requirements.txt -q
        
        # Deploy to Azure
        Write-Host "Publishing to Azure Function App: $FunctionAppName"
        func azure functionapp publish $FunctionAppName --python
        
        if ($LASTEXITCODE -ne 0) {
            throw "Function App deployment failed"
        }
        Write-Host "✓ Backend deployed successfully!" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
} else {
    Write-Host "Backend directory not found: $BackendDir" -ForegroundColor Red
    exit 1
}

# Step 2: Deploy Frontend (Static Web App)
Write-Host "`n[2/3] Deploying Frontend to Static Web App..." -ForegroundColor Yellow
$FrontendDir = Join-Path $RootDir "app\frontend"

if (Test-Path $FrontendDir) {
    Push-Location $FrontendDir
    try {
        # Get the Function App URL
        $FunctionAppUrl = "https://$FunctionAppName.azurewebsites.net/api"
        Write-Host "Backend API URL: $FunctionAppUrl"
        
        # Set environment variable for React build
        $env:REACT_APP_API_URL = $FunctionAppUrl
        
        # Install dependencies and build
        Write-Host "Installing npm dependencies..."
        npm install
        
        Write-Host "Building React app..."
        npm run build
        
        # Get deployment token
        Write-Host "Getting Static Web App deployment token..."
        $Token = az staticwebapp secrets list --name $StaticWebAppName --resource-group $ResourceGroupName --query "properties.apiKey" -o tsv
        
        if ([string]::IsNullOrEmpty($Token)) {
            throw "Could not get Static Web App deployment token"
        }
        
        # Deploy using SWA CLI
        Write-Host "Deploying to Static Web App: $StaticWebAppName"
        npx @azure/static-web-apps-cli deploy ./build --deployment-token $Token
        
        Write-Host "✓ Frontend deployed successfully!" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
} else {
    Write-Host "Frontend directory not found: $FrontendDir" -ForegroundColor Red
    exit 1
}

# Step 3: Seed Sample Data
Write-Host "`n[3/3] Seeding sample data to Cosmos DB..." -ForegroundColor Yellow

# Get Cosmos DB connection info from terraform output
Push-Location $RootDir
try {
    $CosmosEndpoint = terraform output -raw cosmos_db_endpoint 2>$null
    $CosmosKey = terraform output -raw cosmos_db_primary_key 2>$null
    $DatabaseName = terraform output -raw cosmos_db_database_name 2>$null
    
    if ($CosmosEndpoint -and $CosmosKey) {
        Write-Host "Seeding data via Function App API..."
        
        # Seed via API call
        $SeedData = @(
            @{ firstName = "John"; lastName = "Doe"; email = "john.doe@company.com"; department = "Engineering"; position = "Senior Developer" },
            @{ firstName = "Jane"; lastName = "Smith"; email = "jane.smith@company.com"; department = "HR"; position = "HR Manager" },
            @{ firstName = "Bob"; lastName = "Johnson"; email = "bob.j@company.com"; department = "Engineering"; position = "DevOps Engineer" }
        )
        
        foreach ($emp in $SeedData) {
            $body = $emp | ConvertTo-Json
            try {
                Invoke-RestMethod -Uri "$FunctionAppUrl/employees" -Method POST -Body $body -ContentType "application/json"
                Write-Host "  Added: $($emp.firstName) $($emp.lastName)" -ForegroundColor Gray
            }
            catch {
                Write-Host "  Warning: Could not add $($emp.firstName) - may already exist" -ForegroundColor Yellow
            }
        }
        Write-Host "✓ Sample data seeded!" -ForegroundColor Green
    }
    else {
        Write-Host "Could not get Cosmos DB info from terraform output. Skipping seed." -ForegroundColor Yellow
    }
}
finally {
    Pop-Location
}

# Done!
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan

# Get Static Web App URL
$SwaUrl = az staticwebapp show --name $StaticWebAppName --resource-group $ResourceGroupName --query "defaultHostname" -o tsv
Write-Host "`nYour app is live at: https://$SwaUrl" -ForegroundColor Cyan
Write-Host "API endpoint: https://$FunctionAppName.azurewebsites.net/api/employees" -ForegroundColor Cyan
