# App Service module for Azure App Service Architecture

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "${var.app_name}-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1" # Basic plan

  tags = var.tags
}

# App Service
resource "azurerm_linux_web_app" "main" {
  name                = var.app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    always_on = true
    application_stack {
      dotnet_version = "6.0"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "ConnectionStrings__DefaultConnection" = var.database_connection_string
    "ASPNETCORE_ENVIRONMENT"              = "Production"
  }

  # VNet Integration - Commented out for Basic plan
  # virtual_network_subnet_id = var.subnet_id

  tags = var.tags
}

# Private Endpoint for App Service
resource "azurerm_private_endpoint" "app_service" {
  name                = "${var.app_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "app-service-private-connection"
    private_connection_resource_id = azurerm_linux_web_app.main.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# Private DNS Zone for App Service
resource "azurerm_private_dns_zone" "app_service" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "app_service" {
  name                  = "${var.app_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.app_service.name
  virtual_network_id    = data.azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = var.tags
}

# Private DNS A Record
resource "azurerm_private_dns_a_record" "app_service" {
  name                = var.app_name
  zone_name           = azurerm_private_dns_zone.app_service.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.app_service.private_service_connection[0].private_ip_address]

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

# Autoscaling configuration
resource "azurerm_monitor_autoscale_setting" "app_service" {
  name                = "${var.app_name}-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_service_plan.main.id

  profile {
    name = "defaultProfile"

    capacity {
      default = var.min_capacity
      minimum = var.min_capacity
      maximum = var.max_capacity
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        metric_namespace   = "Microsoft.Web/serverfarms"
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
        metric_namespace   = "Microsoft.Web/serverfarms"
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "MemoryPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 80
        metric_namespace   = "Microsoft.Web/serverfarms"
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = var.tags
}

# Application Insights for monitoring
resource "azurerm_application_insights" "main" {
  name                = "${var.app_name}-insights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"

  tags = var.tags
}

# Connect App Service to Application Insights
resource "azurerm_app_service_source_control" "main" {
  app_id                 = azurerm_linux_web_app.main.id
  repo_url               = "https://github.com/Azure-Samples/dotnet-core-api"
  branch                 = "master"
  use_manual_integration = true
}
