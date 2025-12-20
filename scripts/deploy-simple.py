#!/usr/bin/env python3
"""
=============================================================================
OPTION 1: SIMPLEST DEPLOYMENT (Local Machine)
=============================================================================
This script deploys the app from your local machine.
Works because public_network_access_enabled = true on Function App

Usage:
    python deploy-simple.py --function-app <name> --static-web-app <name> --resource-group <name>
    
Or get values automatically from terraform:
    python deploy-simple.py --auto
=============================================================================
"""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

# ANSI colors
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'  # No Color

def print_color(color, message):
    print(f"{color}{message}{Colors.NC}")

def run_command(command, cwd=None, capture=False, check=True):
    """Run a shell command and return output."""
    try:
        result = subprocess.run(
            command,
            shell=True,
            cwd=cwd,
            capture_output=capture,
            text=True,
            check=check
        )
        if capture:
            return result.stdout.strip()
        return True
    except subprocess.CalledProcessError as e:
        if check:
            print_color(Colors.RED, f"Command failed: {command}")
            print_color(Colors.RED, f"Error: {e.stderr if e.stderr else str(e)}")
            sys.exit(1)
        return None

def get_terraform_outputs():
    """Get resource names from terraform output."""
    print("Getting values from terraform output...")
    
    function_app = run_command("terraform output -raw function_app_name", capture=True)
    static_web_app = run_command("terraform output -raw static_web_app_name", capture=True)
    resource_group = run_command("terraform output -raw resource_group_name", capture=True)
    
    return function_app, static_web_app, resource_group

def deploy_backend(function_app_name, backend_dir):
    """Deploy Python Function App."""
    print_color(Colors.YELLOW, "\n[1/3] Deploying Backend to Function App...")
    
    if not backend_dir.exists():
        print_color(Colors.RED, f"Backend directory not found: {backend_dir}")
        sys.exit(1)
    
    os.chdir(backend_dir)
    
    # Install dependencies
    print("Installing Python dependencies...")
    run_command("pip install -r requirements.txt -q")
    
    # Deploy to Azure
    print(f"Publishing to Azure Function App: {function_app_name}")
    run_command(f"func azure functionapp publish {function_app_name} --python")
    
    print_color(Colors.GREEN, "✓ Backend deployed successfully!")

def deploy_frontend(function_app_name, static_web_app_name, resource_group_name, frontend_dir):
    """Deploy React Static Web App."""
    print_color(Colors.YELLOW, "\n[2/3] Deploying Frontend to Static Web App...")
    
    if not frontend_dir.exists():
        print_color(Colors.RED, f"Frontend directory not found: {frontend_dir}")
        sys.exit(1)
    
    os.chdir(frontend_dir)
    
    # Set API URL
    api_url = f"https://{function_app_name}.azurewebsites.net/api"
    os.environ['REACT_APP_API_URL'] = api_url
    print(f"Backend API URL: {api_url}")
    
    # Install dependencies and build
    print("Installing npm dependencies...")
    run_command("npm install --silent")
    
    print("Building React app...")
    run_command("npm run build")
    
    # Get deployment token
    print("Getting Static Web App deployment token...")
    token = run_command(
        f'az staticwebapp secrets list --name {static_web_app_name} '
        f'--resource-group {resource_group_name} --query "properties.apiKey" -o tsv',
        capture=True
    )
    
    if not token:
        print_color(Colors.RED, "Could not get Static Web App deployment token")
        sys.exit(1)
    
    # Deploy
    print(f"Deploying to Static Web App: {static_web_app_name}")
    run_command(f"npx @azure/static-web-apps-cli deploy ./build --deployment-token {token}")
    
    print_color(Colors.GREEN, "✓ Frontend deployed successfully!")

def seed_data(function_app_name):
    """Seed sample employee data."""
    print_color(Colors.YELLOW, "\n[3/3] Seeding sample data to Cosmos DB...")
    
    api_url = f"https://{function_app_name}.azurewebsites.net/api"
    
    # Wait for function app to warm up
    print("Waiting for Function App to be ready...")
    time.sleep(10)
    
    employees = [
        {"firstName": "John", "lastName": "Doe", "email": "john.doe@company.com", "department": "Engineering", "position": "Senior Developer"},
        {"firstName": "Jane", "lastName": "Smith", "email": "jane.smith@company.com", "department": "HR", "position": "HR Manager"},
        {"firstName": "Bob", "lastName": "Johnson", "email": "bob.j@company.com", "department": "Engineering", "position": "DevOps Engineer"},
        {"firstName": "Alice", "lastName": "Williams", "email": "alice.w@company.com", "department": "Finance", "position": "Financial Analyst"},
        {"firstName": "Charlie", "lastName": "Brown", "email": "charlie.b@company.com", "department": "Sales", "position": "Sales Manager"},
    ]
    
    import urllib.request
    import urllib.error
    
    for emp in employees:
        name = f"{emp['firstName']} {emp['lastName']}"
        try:
            data = json.dumps(emp).encode('utf-8')
            req = urllib.request.Request(
                f"{api_url}/employees",
                data=data,
                headers={'Content-Type': 'application/json'},
                method='POST'
            )
            urllib.request.urlopen(req, timeout=30)
            print(f"  Added: {name}")
        except urllib.error.HTTPError as e:
            print_color(Colors.YELLOW, f"  Warning: Could not add {name} (may already exist)")
        except Exception as e:
            print_color(Colors.YELLOW, f"  Warning: Could not add {name}: {e}")
    
    print_color(Colors.GREEN, "✓ Sample data seeded!")

def get_static_web_app_url(static_web_app_name, resource_group_name):
    """Get the Static Web App URL."""
    url = run_command(
        f'az staticwebapp show --name {static_web_app_name} '
        f'--resource-group {resource_group_name} --query "defaultHostname" -o tsv',
        capture=True
    )
    return url

def main():
    parser = argparse.ArgumentParser(
        description='Deploy Employee Management App to Azure',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python deploy-simple.py --auto
  python deploy-simple.py -f func-dte-dev -s swa-dte-dev -r rg-dte-dev
        """
    )
    parser.add_argument('--auto', action='store_true', help='Get values from terraform output')
    parser.add_argument('-f', '--function-app', help='Function App name')
    parser.add_argument('-s', '--static-web-app', help='Static Web App name')
    parser.add_argument('-r', '--resource-group', help='Resource Group name')
    parser.add_argument('--skip-backend', action='store_true', help='Skip backend deployment')
    parser.add_argument('--skip-frontend', action='store_true', help='Skip frontend deployment')
    parser.add_argument('--skip-seed', action='store_true', help='Skip data seeding')
    
    args = parser.parse_args()
    
    # Get script directory
    script_dir = Path(__file__).parent.resolve()
    root_dir = script_dir.parent
    
    print_color(Colors.CYAN, "============================================")
    print_color(Colors.CYAN, "OPTION 1: Simple Local Deployment")
    print_color(Colors.CYAN, "============================================")
    
    # Get resource names
    if args.auto:
        os.chdir(root_dir)
        function_app, static_web_app, resource_group = get_terraform_outputs()
    else:
        if not all([args.function_app, args.static_web_app, args.resource_group]):
            print_color(Colors.RED, "Error: Provide all arguments or use --auto")
            parser.print_help()
            sys.exit(1)
        function_app = args.function_app
        static_web_app = args.static_web_app
        resource_group = args.resource_group
    
    print(f"\nFunction App:    {function_app}")
    print(f"Static Web App:  {static_web_app}")
    print(f"Resource Group:  {resource_group}")
    
    # Deploy
    backend_dir = root_dir / "app" / "backend"
    frontend_dir = root_dir / "app" / "frontend"
    
    if not args.skip_backend:
        deploy_backend(function_app, backend_dir)
    
    if not args.skip_frontend:
        deploy_frontend(function_app, static_web_app, resource_group, frontend_dir)
    
    if not args.skip_seed:
        seed_data(function_app)
    
    # Done!
    print_color(Colors.CYAN, "\n============================================")
    print_color(Colors.GREEN, "DEPLOYMENT COMPLETE!")
    print_color(Colors.CYAN, "============================================")
    
    swa_url = get_static_web_app_url(static_web_app, resource_group)
    print_color(Colors.CYAN, f"\nYour app is live at: https://{swa_url}")
    print_color(Colors.CYAN, f"API endpoint: https://{function_app}.azurewebsites.net/api/employees")

if __name__ == "__main__":
    main()
