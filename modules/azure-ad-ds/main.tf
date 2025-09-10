# Azure AD Domain Services module for Azure App Service Architecture

# Azure AD Domain Services
resource "azurerm_active_directory_domain_service" "main" {
  name                = "${var.domain_name}-aadds"
  location            = var.location
  resource_group_name = var.resource_group_name

  domain_name = var.domain_name
  sku         = "Standard"
  filtered_sync_enabled = false

  initial_replica_set {
    subnet_id = var.subnet_id
  }

  notifications {
    additional_recipients = []
    notify_dc_admins      = true
    notify_global_admins  = true
  }

  security {
    sync_kerberos_passwords = true
    sync_ntlm_passwords     = true
    sync_on_prem_passwords  = true
  }

  tags = var.tags
}

# Network Security Group for Azure AD DS
resource "azurerm_network_security_group" "aadds" {
  name                = "${var.domain_name}-aadds-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow inbound LDAPS
  security_rule {
    name                       = "AllowLDAPS"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "636"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow inbound LDAP
  security_rule {
    name                       = "AllowLDAP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow inbound Kerberos
  security_rule {
    name                       = "AllowKerberos"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "88"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow inbound Kerberos UDP
  security_rule {
    name                       = "AllowKerberosUDP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "88"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow inbound DNS
  security_rule {
    name                       = "AllowDNS"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow inbound DNS UDP
  security_rule {
    name                       = "AllowDNSUDP"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow inbound RPC
  security_rule {
    name                       = "AllowRPC"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "135"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow inbound NetBIOS
  security_rule {
    name                       = "AllowNetBIOS"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_ranges    = ["137", "138"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow inbound SMB
  security_rule {
    name                       = "AllowSMB"
    priority                   = 1008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow inbound RPC Dynamic Ports
  security_rule {
    name                       = "AllowRPCDynamic"
    priority                   = 1009
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1024-65535"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "aadds" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.aadds.id
}

# Log Analytics Workspace for Azure AD DS
resource "azurerm_log_analytics_workspace" "aadds" {
  name                = "aadds-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Diagnostic Settings for Azure AD DS
resource "azurerm_monitor_diagnostic_setting" "aadds" {
  name                       = "${var.domain_name}-aadds-diagnostics"
  target_resource_id         = azurerm_active_directory_domain_service.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aadds.id

  enabled_log {
    category = "SystemSecurity"
  }

  enabled_log {
    category = "AccountManagement"
  }

  enabled_log {
    category = "LogonLogoff"
  }

  enabled_log {
    category = "ObjectAccess"
  }

  enabled_log {
    category = "PolicyChange"
  }

  enabled_log {
    category = "PrivilegeUse"
  }

  enabled_log {
    category = "DetailedTracking"
  }

  enabled_log {
    category = "DirectoryServiceAccess"
  }

  enabled_log {
    category = "AccountLogon"
  }

  metric {
    category = "AllMetrics"
  }
}
