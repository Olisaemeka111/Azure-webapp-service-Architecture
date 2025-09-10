# Outputs for Azure App Service Architecture

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# Networking outputs
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

# App Service outputs
output "app_service_name" {
  description = "Name of the App Service"
  value       = module.app_service.app_service_name
}

output "app_service_fqdn" {
  description = "FQDN of the App Service"
  value       = module.app_service.app_service_fqdn
}

output "app_service_url" {
  description = "URL of the App Service"
  value       = module.app_service.app_service_url
}

# Front Door outputs
output "front_door_name" {
  description = "Name of the Front Door"
  value       = module.front_door.front_door_name
}

output "front_door_fqdn" {
  description = "FQDN of the Front Door"
  value       = module.front_door.front_door_fqdn
}

output "front_door_url" {
  description = "URL of the Front Door"
  value       = module.front_door.front_door_url
}

# Database outputs
output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = module.sql_database.server_name
}

output "sql_database_name" {
  description = "Name of the SQL Database"
  value       = module.sql_database.database_name
}

output "sql_server_fqdn" {
  description = "FQDN of the SQL Server"
  value       = module.sql_database.server_fqdn
}

# Bastion outputs
output "bastion_name" {
  description = "Name of the Azure Bastion"
  value       = module.bastion.bastion_name
}

output "bastion_fqdn" {
  description = "FQDN of the Azure Bastion"
  value       = module.bastion.bastion_fqdn
}

# Monitoring outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "application_insights_id" {
  description = "ID of the Application Insights"
  value       = module.monitoring.application_insights_id
}

# Azure AD DS outputs - Commented out due to module being disabled
# output "azure_ad_ds_domain_name" {
#   description = "Domain name of Azure AD DS"
#   value       = module.azure_ad_ds.domain_name
# }
