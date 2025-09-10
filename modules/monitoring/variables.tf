# Variables for monitoring module

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "workspace_name" {
  description = "Name of the Log Analytics workspace"
  type        = string
}

variable "app_service_id" {
  description = "ID of the App Service to monitor"
  type        = string
}

variable "sql_server_id" {
  description = "ID of the SQL Server to monitor"
  type        = string
}

variable "front_door_id" {
  description = "ID of the Front Door to monitor"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
