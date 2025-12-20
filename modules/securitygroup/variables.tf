# ─────────────────────────────────────────────────────────────
# Security Group Module - Input Variables
# ─────────────────────────────────────────────────────────────

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "subnet_configs" {
  description = "Map of subnet configurations"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = list(string)
  }))
  default = {}
}

variable "subnet_ids" {
  description = "Map of subnet keys to their IDs"
  type        = map(string)
  default     = {}
}

variable "enable_flow_logs" {
  description = "Enable network flow logs for security monitoring"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Network flow logs retention period"
  type        = number
  default     = 30
}
