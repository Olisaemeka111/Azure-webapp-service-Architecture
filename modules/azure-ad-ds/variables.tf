# Variables for Azure AD DS module

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "domain_name" {
  description = "Domain name for Azure AD DS"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for Azure AD DS"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
