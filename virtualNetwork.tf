# Virtual Network Configuration

module "virtualnetwork" {
  source = "./modules/virtualnetwork"

  name                = "vnet-${local.name_prefix}"
  location            = var.azure_region
  resource_group_name = module.resource_group.name
  address_space       = var.vnet_address_space
  tags                = local.common_tags

  depends_on = [module.resource_group]
}
