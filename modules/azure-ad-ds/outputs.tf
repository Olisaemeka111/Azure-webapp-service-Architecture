# Outputs for Azure AD DS module

output "aadds_id" {
  description = "ID of the Azure AD Domain Services"
  value       = azurerm_active_directory_domain_service.main.id
}

output "aadds_name" {
  description = "Name of the Azure AD Domain Services"
  value       = azurerm_active_directory_domain_service.main.name
}

output "domain_name" {
  description = "Domain name of Azure AD DS"
  value       = azurerm_active_directory_domain_service.main.domain_name
}

output "domain_controller_ip_addresses" {
  description = "IP addresses of the domain controllers"
  value       = azurerm_active_directory_domain_service.main.initial_replica_set[0].domain_controller_ip_addresses
}

# Note: service_status output removed as attribute is not available

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.aadds.id
}
