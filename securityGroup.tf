# Network Security Groups Configuration

module "securitygroup" {
  source = "./modules/securitygroup"

  environment         = var.environment
  resource_group_name = module.resource_group.name
  tags                = local.common_tags
  
  subnet_configs = {
    function_app = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Web", "Microsoft.Storage"]
    }
    app_service = {
      address_prefixes  = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Web"]
    }
    private_endpoints = {
      address_prefixes  = ["10.0.3.0/24"]
      service_endpoints = []
    }
    data = {
      address_prefixes  = ["10.0.4.0/24"]
      service_endpoints = ["Microsoft.AzureCosmosDB", "Microsoft.KeyVault", "Microsoft.Storage"]
    }
  }
  
  subnet_ids = module.virtualsubnet.subnet_ids

  depends_on = [module.virtualsubnet]
}
