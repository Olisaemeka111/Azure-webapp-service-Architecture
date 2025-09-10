# Outputs for networking module

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "app_service_subnet_id" {
  description = "ID of the App Service subnet"
  value       = azurerm_subnet.app_service.id
}

output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = azurerm_subnet.database.id
}

output "bastion_subnet_id" {
  description = "ID of the Bastion subnet"
  value       = azurerm_subnet.bastion.id
}

output "private_endpoint_subnet_id" {
  description = "ID of the private endpoint subnet"
  value       = azurerm_subnet.private_endpoint.id
}

output "app_service_nsg_id" {
  description = "ID of the App Service NSG"
  value       = azurerm_network_security_group.app_service.id
}

output "database_nsg_id" {
  description = "ID of the database NSG"
  value       = azurerm_network_security_group.database.id
}

output "bastion_nsg_id" {
  description = "ID of the Bastion NSG"
  value       = azurerm_network_security_group.bastion.id
}
