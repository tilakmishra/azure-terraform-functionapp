# ═══════════════════════════════════════════════════════════════════════════════
# Log Analytics Module - Variables
# ═══════════════════════════════════════════════════════════════════════════════

variable "name" {
  description = "Name of the Log Analytics Workspace"
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

variable "retention_in_days" {
  description = "Data retention in days (30-730)"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

