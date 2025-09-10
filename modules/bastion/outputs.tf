# Outputs for Bastion module

output "bastion_id" {
  description = "ID of the Azure Bastion"
  value       = azurerm_bastion_host.main.id
}

output "bastion_name" {
  description = "Name of the Azure Bastion"
  value       = azurerm_bastion_host.main.name
}

output "bastion_fqdn" {
  description = "FQDN of the Azure Bastion"
  value       = azurerm_bastion_host.main.dns_name
}

output "bastion_url" {
  description = "URL of the Azure Bastion"
  value       = "https://${azurerm_bastion_host.main.dns_name}"
}

output "public_ip_id" {
  description = "ID of the public IP"
  value       = azurerm_public_ip.bastion.id
}

output "public_ip_address" {
  description = "Public IP address of the Bastion"
  value       = azurerm_public_ip.bastion.ip_address
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.bastion.id
}
