# Azure Bastion module for Azure App Service Architecture

# Public IP for Bastion
resource "azurerm_public_ip" "bastion" {
  name                = "${var.bastion_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# Azure Bastion Host
resource "azurerm_bastion_host" "main" {
  name                = var.bastion_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = var.tags
}

# Network Security Group for Bastion
resource "azurerm_network_security_group" "bastion" {
  name                = "${var.bastion_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow HTTPS inbound from Internet
  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Allow Gateway Manager inbound
  security_rule {
    name                       = "AllowGatewayManagerInbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  # Allow Azure Load Balancer inbound
  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Allow Bastion Host Communication
  security_rule {
    name                       = "AllowBastionHostCommunication"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow SSH RDP outbound
  security_rule {
    name                       = "AllowSshRdpOutbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow Azure Cloud outbound
  security_rule {
    name                       = "AllowAzureCloudOutbound"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  # Allow Bastion Communication
  security_rule {
    name                       = "AllowBastionCommunication"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow Get Session Information
  security_rule {
    name                       = "AllowGetSessionInformation"
    priority                   = 1003
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = var.tags
}

# Associate NSG with Bastion subnet
resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

# Log Analytics Workspace for Bastion logs
resource "azurerm_log_analytics_workspace" "bastion" {
  name                = "${var.bastion_name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Diagnostic Settings for Bastion
resource "azurerm_monitor_diagnostic_setting" "bastion" {
  name                       = "${var.bastion_name}-diagnostics"
  target_resource_id         = azurerm_bastion_host.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.bastion.id

  enabled_log {
    category = "BastionAuditLogs"
  }

  enabled_log {
    category = "BastionAuditLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
