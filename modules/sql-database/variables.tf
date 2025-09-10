# Variables for SQL Database module

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "server_name" {
  description = "Name of the SQL Server"
  type        = string
}

variable "database_name" {
  description = "Name of the SQL Database"
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

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup"
  type        = bool
  default     = true
}

variable "zone_redundant" {
  description = "Enable zone redundancy"
  type        = bool
  default     = true
}

# Key Vault integration can be added if needed

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
