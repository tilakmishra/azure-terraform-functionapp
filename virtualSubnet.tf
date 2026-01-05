# Virtual Subnet Configuration - Enterprise Secure

module "virtualsubnet" {
  source = "./modules/virtualsubnet"

  environment         = var.environment
  resource_group_name = module.resource_group.name
  vnet_name           = module.virtualnetwork.name

  subnet_configs = {
    # Function App VNet Integration subnet (requires delegation)
    function_app = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Web", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.AzureCosmosDB"]
      delegation = {
        name         = "function-app-delegation"
        service_name = "Microsoft.Web/serverFarms"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    # App Service VNet Integration subnet
    app_service = {
      address_prefixes  = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Web", "Microsoft.KeyVault"]
      delegation = {
        name         = "app-service-delegation"
        service_name = "Microsoft.Web/serverFarms"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    # Private Endpoints subnet (no delegation needed)
    private_endpoints = {
      address_prefixes  = ["10.0.3.0/24"]
      service_endpoints = []
    }
    # Data subnet with service endpoints
    data = {
      address_prefixes  = ["10.0.4.0/24"]
      service_endpoints = ["Microsoft.AzureCosmosDB", "Microsoft.KeyVault", "Microsoft.Storage"]
    }
  }

  depends_on = [module.virtualnetwork]
}
