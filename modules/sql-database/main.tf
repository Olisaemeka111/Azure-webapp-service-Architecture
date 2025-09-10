# SQL Database module for Azure App Service Architecture

# Random password for SQL Server
resource "random_password" "sql_admin_password" {
  length  = 16
  special = true
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = var.server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = random_password.sql_admin_password.result

  # Azure AD administrator can be configured later

  tags = var.tags
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name           = var.database_name
  server_id      = azurerm_mssql_server.main.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 4
  sku_name       = "BC_Gen5_2" # Business Critical for HA/DR
  zone_redundant = var.zone_redundant

  # Backup configuration
  short_term_retention_policy {
    retention_days = 7
  }

  long_term_retention_policy {
    weekly_retention  = "P1W"
    monthly_retention = "P1M"
    yearly_retention  = "P1Y"
    week_of_year      = 1
  }

  geo_backup_enabled = var.geo_redundant_backup_enabled

  tags = var.tags
}

# Virtual Network Rule for SQL Server
resource "azurerm_mssql_virtual_network_rule" "main" {
  name      = "sql-vnet-rule"
  server_id = azurerm_mssql_server.main.id
  subnet_id = var.subnet_id
}

# Private Endpoint for SQL Server
resource "azurerm_private_endpoint" "sql" {
  name                = "${var.server_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "sql-private-connection"
    private_connection_resource_id = azurerm_mssql_server.main.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# Private DNS Zone for SQL Server
resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "${var.server_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = data.azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = var.tags
}

# Private DNS A Record
resource "azurerm_private_dns_a_record" "sql" {
  name                = var.server_name
  zone_name           = azurerm_private_dns_zone.sql.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.sql.private_service_connection[0].private_ip_address]

  tags = var.tags
}

# Data source to get subnet information
data "azurerm_subnet" "main" {
  name                 = split("/", var.subnet_id)[10]
  virtual_network_name = split("/", var.subnet_id)[8]
  resource_group_name  = split("/", var.subnet_id)[4]
}

# Data source to get VNet information
data "azurerm_virtual_network" "main" {
  name                = split("/", var.subnet_id)[8]
  resource_group_name = split("/", var.subnet_id)[4]
}

# SQL Server Firewall Rule (for Azure services)
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Note: Key Vault integration can be added if needed
