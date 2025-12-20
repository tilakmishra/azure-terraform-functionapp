# ═══════════════════════════════════════════════════════════════════════════════
# Private Endpoint Module - Variables
# ═══════════════════════════════════════════════════════════════════════════════

variable "name" {
  description = "Name of the private endpoint"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
}

variable "target_resource_id" {
  description = "ID of the resource to connect to"
  type        = string
}

variable "subresource_names" {
  description = "Subresource names (e.g., ['blob'], ['vault'], ['sites'])"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

