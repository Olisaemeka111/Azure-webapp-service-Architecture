# Variables for App Service module

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "app_name" {
  description = "Name of the App Service"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for VNet integration"
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "ID of the subnet for private endpoint"
  type        = string
}

variable "min_capacity" {
  description = "Minimum capacity for autoscaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum capacity for autoscaling"
  type        = number
  default     = 10
}

variable "database_connection_string" {
  description = "Database connection string"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
