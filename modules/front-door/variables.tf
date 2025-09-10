# Variables for Front Door module

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "front_door_name" {
  description = "Name of the Front Door profile"
  type        = string
}

variable "app_service_fqdn" {
  description = "FQDN of the App Service"
  type        = string
}

variable "app_service_private_link_target_id" {
  description = "Private link target ID for App Service"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the custom domain"
  type        = string
  default     = "example.com"
}

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

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
