# ─────────────────────────────────────────────────────────────
# Virtual Subnet Module - Outputs
# ─────────────────────────────────────────────────────────────

output "subnets" {
  description = "Map of subnets with their IDs and details"
  value = {
    for key, subnet in azurerm_subnet.subnets : key => {
      id                = subnet.id
      name              = subnet.name
      address_prefixes  = subnet.address_prefixes
      service_endpoints = subnet.service_endpoints
    }
  }
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = {
    for key, subnet in azurerm_subnet.subnets : key => subnet.id
  }
}

output "subnet_names" {
  description = "Map of subnet keys to their names"
  value = {
    for key, subnet in azurerm_subnet.subnets : key => subnet.name
  }
}
