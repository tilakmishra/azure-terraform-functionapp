# Function App Module - Outputs

output "id" {
  description = "Function App ID"
  value       = azurerm_linux_function_app.main.id
}

output "name" {
  description = "Function App name"
  value       = azurerm_linux_function_app.main.name
}

output "default_hostname" {
  description = "Function App hostname"
  value       = azurerm_linux_function_app.main.default_hostname
}

output "identity_principal_id" {
  description = "Managed Identity principal ID"
  value       = azurerm_linux_function_app.main.identity[0].principal_id
}
