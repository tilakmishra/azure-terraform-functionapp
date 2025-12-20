# Static Web App Module - Outputs

output "id" {
  description = "Static Web App ID"
  value       = azurerm_static_web_app.main.id
}

output "name" {
  description = "Static Web App name"
  value       = azurerm_static_web_app.main.name
}

output "default_host_name" {
  description = "Default hostname"
  value       = azurerm_static_web_app.main.default_host_name
}
