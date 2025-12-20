# ─────────────────────────────────────────────────────────────
# Security Group Module - Outputs
# ─────────────────────────────────────────────────────────────

output "nsgs" {
  description = "Map of NSGs"
  value = {
    for key, nsg in azurerm_network_security_group.nsgs : key => {
      id   = nsg.id
      name = nsg.name
    }
  }
}

output "nsg_ids" {
  description = "Map of NSG names to their IDs"
  value = {
    for key, nsg in azurerm_network_security_group.nsgs : key => nsg.id
  }
}

output "nsg_names" {
  description = "Map of NSG keys to their names"
  value = {
    for key, nsg in azurerm_network_security_group.nsgs : key => nsg.name
  }
}
