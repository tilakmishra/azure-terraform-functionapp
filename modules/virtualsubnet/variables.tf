# ─────────────────────────────────────────────────────────────
# Virtual Subnet Module - Input Variables
# ─────────────────────────────────────────────────────────────

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "vnet_name" {
  description = "Virtual Network name"
  type        = string
}

variable "subnet_configs" {
  description = "Map of subnet configurations with address prefixes, service endpoints, and optional delegation"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = list(string)
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = list(string)
    }))
  }))
  default = {}
}
