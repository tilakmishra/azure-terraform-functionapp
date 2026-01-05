output "id" {
  description = "ID of the Private DNS zone"
  value       = azurerm_private_dns_zone.main.id
}

output "name" {
  description = "Name of the Private DNS zone"
  value       = azurerm_private_dns_zone.main.name
}
