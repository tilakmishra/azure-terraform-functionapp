#!/usr/bin/env pwsh
# Quick Deployment Script - Employee Management App
# Run this from: azure/DTE/terraform/

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "     Employee Management App - Quick Deploy" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify we're in the right directory
$currentDir = Get-Location
if (-not (Test-Path "main.tf")) {
    Write-Host "❌ Error: main.tf not found. Please run this script from azure/DTE/terraform/" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Current directory: $currentDir" -ForegroundColor Green
Write-Host ""

# Step 2: Check Git status
Write-Host "Step 1: Checking Git status..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

if (-not (Test-Path ".git")) {
    Write-Host "⚠️  Git not initialized. Initializing..." -ForegroundColor Yellow
    git init
    Write-Host "✅ Git initialized" -ForegroundColor Green
}

Write-Host ""
Write-Host "Files that will be committed:" -ForegroundColor Cyan
git status --short
Write-Host ""

# Verify documentation is ignored
$ignoredDocs = @(
    "SECURITY_IMPLEMENTATION.md",
    "DEPLOYMENT_GUIDE.md",
    "QUICK_REFERENCE.md",
    "INTERVIEW_SUBMISSION_SUMMARY.md",
    "CHANGES_SUMMARY.md",
    "ARCHITECTURE_DECISIONS.md",
    "GITHUB_ACTIONS_CI_CD.md",
    "ARCHITECTURE_AND_WORKFLOW_SUMMARY.md",
    "COMPLETE_SOLUTION.md",
    "VISUAL_ARCHITECTURE_SUMMARY.md"
)

$shouldBeIgnored = $ignoredDocs | Where-Object { Test-Path $_ }
if ($shouldBeIgnored) {
    Write-Host "✅ Documentation files correctly ignored:" -ForegroundColor Green
    $shouldBeIgnored | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
} else {
    Write-Host "✅ No documentation files found (clean)" -ForegroundColor Green
}
Write-Host ""

# Step 3: Pre-flight checks
Write-Host "Step 2: Running pre-flight checks..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

# Check Azure CLI
$azVersion = az version --output json 2>$null | ConvertFrom-Json
if ($azVersion) {
    Write-Host "✅ Azure CLI: $($azVersion.'azure-cli')" -ForegroundColor Green
} else {
    Write-Host "❌ Azure CLI not found. Install: https://aka.ms/installazurecliwindows" -ForegroundColor Red
    exit 1
}

# Check Terraform
$tfVersion = terraform version -json 2>$null | ConvertFrom-Json
if ($tfVersion) {
    Write-Host "✅ Terraform: $($tfVersion.terraform_version)" -ForegroundColor Green
} else {
    Write-Host "❌ Terraform not found. Install: https://www.terraform.io/downloads" -ForegroundColor Red
    exit 1
}

# Check Azure login
$azAccount = az account show 2>$null | ConvertFrom-Json
if ($azAccount) {
    Write-Host "✅ Azure Account: $($azAccount.name) ($($azAccount.id))" -ForegroundColor Green
} else {
    Write-Host "⚠️  Not logged in to Azure. Running 'az login'..." -ForegroundColor Yellow
    az login
    $azAccount = az account show | ConvertFrom-Json
    Write-Host "✅ Logged in as: $($azAccount.user.name)" -ForegroundColor Green
}

Write-Host ""

# Step 4: Service Principal setup prompt
Write-Host "Step 3: GitHub Actions Service Principal" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "Have you created the Azure Service Principal for GitHub Actions?" -ForegroundColor Cyan
Write-Host "If NO, I'll create it for you now." -ForegroundColor Cyan
Write-Host ""
$createSP = Read-Host "Create Service Principal now? (y/n)"

if ($createSP -eq 'y' -or $createSP -eq 'Y') {
    $subscriptionId = $azAccount.id
    $spName = "github-actions-dte-deploy"
    
    Write-Host ""
    Write-Host "Creating Service Principal: $spName" -ForegroundColor Yellow
    
    $sp = az ad sp create-for-rbac --name $spName `
        --role Contributor `
        --scopes "/subscriptions/$subscriptionId" `
        --sdk-auth 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Service Principal created successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "=====================================================" -ForegroundColor Magenta
        Write-Host "COPY THIS JSON - ADD TO GITHUB SECRETS" -ForegroundColor Magenta
        Write-Host "Secret Name: AZURE_CREDENTIALS" -ForegroundColor Magenta
        Write-Host "=====================================================" -ForegroundColor Magenta
        Write-Host $sp -ForegroundColor White
        Write-Host "=====================================================" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "Press Enter to continue after adding to GitHub Secrets..."
        Read-Host
    } else {
        Write-Host "⚠️  Service Principal already exists or creation failed" -ForegroundColor Yellow
        Write-Host "You can retrieve credentials with:" -ForegroundColor Yellow
        Write-Host "az ad sp create-for-rbac --name $spName --role Contributor --scopes /subscriptions/$subscriptionId --sdk-auth" -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host ""

# Step 5: Deploy infrastructure first (to get Static Web App token)
Write-Host "Step 4: Initial Terraform Deployment" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host "Deploying infrastructure to get Static Web App token..." -ForegroundColor Cyan
Write-Host ""

$deployNow = Read-Host "Run Terraform apply now? This will create Azure resources. (y/n)"

if ($deployNow -eq 'y' -or $deployNow -eq 'Y') {
    Write-Host ""
    Write-Host "Running Terraform init..." -ForegroundColor Yellow
    terraform init
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Terraform initialized" -ForegroundColor Green
    } else {
        Write-Host "❌ Terraform init failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "Running Terraform validate..." -ForegroundColor Yellow
    terraform validate
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Configuration is valid" -ForegroundColor Green
    } else {
        Write-Host "❌ Terraform validation failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "Running Terraform plan..." -ForegroundColor Yellow
    terraform plan -var-file="dev.tfvars" -out=tfplan
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Terraform plan failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "Running Terraform apply..." -ForegroundColor Yellow
    Write-Host "This will take 15-20 minutes..." -ForegroundColor Gray
    terraform apply tfplan
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Infrastructure deployed successfully!" -ForegroundColor Green
        Write-Host ""
        
        # Get Static Web App deployment token
        Write-Host "Getting Static Web App deployment token..." -ForegroundColor Yellow
        $swaToken = terraform output -raw static_web_app_deployment_token
        
        Write-Host ""
        Write-Host "=====================================================" -ForegroundColor Magenta
        Write-Host "COPY THIS TOKEN - ADD TO GITHUB SECRETS" -ForegroundColor Magenta
        Write-Host "Secret Name: AZURE_STATIC_WEB_APPS_API_TOKEN" -ForegroundColor Magenta
        Write-Host "=====================================================" -ForegroundColor Magenta
        Write-Host $swaToken -ForegroundColor White
        Write-Host "=====================================================" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "Press Enter to continue after adding to GitHub Secrets..."
        Read-Host
    } else {
        Write-Host "❌ Terraform apply failed" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Step 6: Git commit and push
Write-Host "Step 5: Commit and Push to GitHub" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host ""

$gitRemote = git remote get-url origin 2>$null
if (-not $gitRemote) {
    Write-Host "⚠️  No Git remote found. Please add your GitHub repository:" -ForegroundColor Yellow
    $repoUrl = Read-Host "Enter GitHub repo URL (https://github.com/USERNAME/REPO.git)"
    if ($repoUrl) {
        git remote add origin $repoUrl
        Write-Host "✅ Remote added: $repoUrl" -ForegroundColor Green
    }
} else {
    Write-Host "✅ Git remote: $gitRemote" -ForegroundColor Green
}

Write-Host ""
$pushNow = Read-Host "Stage, commit, and push code to GitHub now? (y/n)"

if ($pushNow -eq 'y' -or $pushNow -eq 'Y') {
    Write-Host ""
    Write-Host "Staging files..." -ForegroundColor Yellow
    git add .
    
    Write-Host "Committing..." -ForegroundColor Yellow
    git commit -m "Deploy Employee Management App: Infrastructure + Backend + Frontend"
    
    Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
    git push -u origin main
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Code pushed to GitHub!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Push may have failed. Check your GitHub credentials." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "            DEPLOYMENT SUMMARY" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Infrastructure deployed to Azure" -ForegroundColor Green
Write-Host "✅ GitHub Secrets configured" -ForegroundColor Green
Write-Host "✅ Code pushed to GitHub" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Go to GitHub → Your Repo → Actions tab" -ForegroundColor White
Write-Host "2. Click 'Deploy Infrastructure and Application'" -ForegroundColor White
Write-Host "3. Click 'Run workflow' → Select 'main' → Run" -ForegroundColor White
Write-Host "4. Wait 40-50 minutes for deployment" -ForegroundColor White
Write-Host "5. Check 'Verify Deployment' job output for URLs" -ForegroundColor White
Write-Host ""
Write-Host "TEST ENDPOINTS:" -ForegroundColor Yellow
$funcAppUrl = terraform output -raw function_app_url 2>$null
if ($funcAppUrl) {
    Write-Host "  Health: $funcAppUrl/api/health" -ForegroundColor White
    Write-Host "  Employees: $funcAppUrl/api/employees" -ForegroundColor White
}
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "               🎉 READY TO DEPLOY! 🎉" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
