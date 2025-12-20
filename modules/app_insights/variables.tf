# ═══════════════════════════════════════════════════════════════════════════════
# Application Insights Module - Variables
# ═══════════════════════════════════════════════════════════════════════════════

variable "name" {
  description = "Name of Application Insights"
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

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
}

variable "retention_in_days" {
  description = "Data retention in days"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

