# Variables for Bastion module

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "bastion_name" {
  description = "Name of the Azure Bastion"
  type        = string
}

variable "subnet_id" {
  description = "ID of the Bastion subnet"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
