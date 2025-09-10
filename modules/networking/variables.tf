# Variables for networking module

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "address_space" {
  description = "Address space for the VNet"
  type        = list(string)
}

variable "app_service_subnet_cidr" {
  description = "CIDR block for App Service subnet"
  type        = string
}

variable "database_subnet_cidr" {
  description = "CIDR block for database subnet"
  type        = string
}

variable "bastion_subnet_cidr" {
  description = "CIDR block for Bastion subnet"
  type        = string
}

variable "private_endpoint_subnet_cidr" {
  description = "CIDR block for private endpoint subnet"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
