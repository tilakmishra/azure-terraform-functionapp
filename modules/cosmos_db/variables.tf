# Cosmos DB Module - Variables

variable "name" {
  description = "Cosmos DB account name"
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

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "employeedb"
}

variable "container_name" {
  description = "Container name"
  type        = string
  default     = "employees"
}

variable "partition_key_path" {
  description = "Partition key path"
  type        = string
  default     = "/departmentId"
}

variable "throughput" {
  description = "Provisioned throughput (RUs)"
  type        = number
  default     = 400
}

# Network Security Variables (Required - Enterprise Security)
variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed via service endpoints"
  type        = list(string)
}

# Monitoring Variables
variable "enable_diagnostics" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
  default     = null
}
