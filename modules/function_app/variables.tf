# Function App Module - Variables

variable "name" {
  description = "Function App name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "storage_account_name" {
  description = "Storage account name"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "python_version" {
  description = "Python version"
  type        = string
  default     = "3.11"
}

variable "app_settings" {
  description = "App settings"
  type        = map(string)
  default     = {}
}

variable "app_insights_connection_string" {
  description = "Application Insights connection string"
  type        = string
  default     = ""
}

# Network Security Variables (Required - Enterprise Security)
variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoints (inbound traffic)"
  type        = string
}

variable "vnet_integration_subnet_id" {
  description = "Subnet ID for VNet integration (outbound traffic)"
  type        = string
}
