# Main Terraform configuration for Azure App Service Architecture

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Data sources
data "azurerm_client_config" "current" {}

# Local variables
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location

  tags = local.common_tags
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  vnet_name          = "${var.project_name}-${var.environment}-vnet"
  address_space      = var.vnet_address_space

  # Subnet configurations
  app_service_subnet_cidr = var.app_service_subnet_cidr
  database_subnet_cidr    = var.database_subnet_cidr
  bastion_subnet_cidr     = var.bastion_subnet_cidr
  private_endpoint_subnet_cidr = var.private_endpoint_subnet_cidr

  tags = local.common_tags
}

# Azure AD DS Module - Commented out due to provider registration requirements
# module "azure_ad_ds" {
#   source = "./modules/azure-ad-ds"
#
#   resource_group_name = azurerm_resource_group.main.name
#   location           = azurerm_resource_group.main.location
#   domain_name        = var.domain_name
#   subnet_id          = module.networking.private_endpoint_subnet_id
#
#   tags = local.common_tags
# }

# Azure SQL Database Module
module "sql_database" {
  source = "./modules/sql-database"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  server_name        = "${var.project_name}-${var.environment}-sql"
  database_name      = var.database_name
  subnet_id          = module.networking.database_subnet_id
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id

  # HA/DR Configuration
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled
  zone_redundant               = var.zone_redundant

  tags = local.common_tags
}

# App Service Module
module "app_service" {
  source = "./modules/app-service"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  app_name           = "${var.project_name}-${var.environment}-app"
  subnet_id          = module.networking.app_service_subnet_id
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id

  # Autoscaling configuration
  min_capacity = var.app_service_min_capacity
  max_capacity = var.app_service_max_capacity

  # Database connection
  database_connection_string = module.sql_database.connection_string

  tags = local.common_tags
}

# Azure Bastion Module
module "bastion" {
  source = "./modules/bastion"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  bastion_name       = "${var.project_name}-${var.environment}-bastion"
  subnet_id          = module.networking.bastion_subnet_id

  tags = local.common_tags
}

# Azure Front Door Module
module "front_door" {
  source = "./modules/front-door"

  resource_group_name = azurerm_resource_group.main.name
  front_door_name     = "${var.project_name}-${var.environment}-fd"
  app_service_fqdn    = module.app_service.app_service_fqdn
  app_service_private_link_target_id = module.app_service.app_service_id
  location           = azurerm_resource_group.main.location

  # WAF Configuration
  waf_enabled = var.waf_enabled
  waf_mode    = var.waf_mode

  tags = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  workspace_name     = "${var.project_name}-${var.environment}-monitor"

  # Resources to monitor
  app_service_id = module.app_service.app_service_id
  sql_server_id  = module.sql_database.server_id
  front_door_id  = module.front_door.front_door_id

  tags = local.common_tags
}
