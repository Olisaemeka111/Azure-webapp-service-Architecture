# Variables for Azure App Service Architecture

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "azure-app"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West US 2"
}

variable "domain_name" {
  description = "Domain name for Azure AD DS"
  type        = string
  default     = "corp.local"
}

# Networking variables
variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "app_service_subnet_cidr" {
  description = "CIDR block for App Service subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "database_subnet_cidr" {
  description = "CIDR block for database subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "bastion_subnet_cidr" {
  description = "CIDR block for Bastion subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_endpoint_subnet_cidr" {
  description = "CIDR block for private endpoint subnet"
  type        = string
  default     = "10.0.4.0/24"
}

# App Service variables
variable "app_service_min_capacity" {
  description = "Minimum capacity for App Service autoscaling"
  type        = number
  default     = 1
}

variable "app_service_max_capacity" {
  description = "Maximum capacity for App Service autoscaling"
  type        = number
  default     = 10
}

# Database variables
variable "database_name" {
  description = "Name of the SQL database"
  type        = string
  default     = "appdb"
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup for SQL Database"
  type        = bool
  default     = true
}

variable "zone_redundant" {
  description = "Enable zone redundancy for SQL Database"
  type        = bool
  default     = true
}

# Front Door variables
variable "waf_enabled" {
  description = "Enable WAF on Front Door"
  type        = bool
  default     = true
}

variable "waf_mode" {
  description = "WAF mode (Prevention or Detection)"
  type        = string
  default     = "Prevention"
}
