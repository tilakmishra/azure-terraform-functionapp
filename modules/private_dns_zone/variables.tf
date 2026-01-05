variable "zone_name" {
  description = "Name of the Private DNS zone (e.g., privatelink.documents.azure.com)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "virtual_network_id" {
  description = "ID of the Virtual Network to link"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
