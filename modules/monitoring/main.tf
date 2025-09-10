# Monitoring module for Azure App Service Architecture

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "${var.workspace_name}-insights"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = var.tags
}

# Azure Monitor Action Group
resource "azurerm_monitor_action_group" "main" {
  name                = "${var.workspace_name}-action-group"
  resource_group_name = var.resource_group_name
  short_name          = "alerts"

  email_receiver {
    name          = "admin"
    email_address = "admin@contoso.com"
  }

  tags = var.tags
}

# Metric Alert for App Service CPU
resource "azurerm_monitor_metric_alert" "app_service_cpu" {
  name                = "${var.workspace_name}-app-service-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [var.app_service_id]
  description         = "Action will be triggered when App Service CPU is high"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "CpuPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# Metric Alert for SQL Database DTU
resource "azurerm_monitor_metric_alert" "sql_dtu" {
  name                = "${var.workspace_name}-sql-dtu"
  resource_group_name = var.resource_group_name
  scopes              = [var.sql_server_id]
  description         = "Action will be triggered when SQL Database DTU is high"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "dtu_consumption_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# Metric Alert for Front Door Request Rate
resource "azurerm_monitor_metric_alert" "front_door_requests" {
  name                = "${var.workspace_name}-front-door-requests"
  resource_group_name = var.resource_group_name
  scopes              = [var.front_door_id]
  description         = "Action will be triggered when Front Door request rate is high"
  severity            = 3
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Cdn/profiles"
    metric_name      = "RequestCount"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 1000
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# Note: Log Analytics queries can be created manually in the Azure portal

# Azure Security Center (Defender for Cloud)
# Security Center Pricing - Commented out as these are subscription-level resources
# resource "azurerm_security_center_subscription_pricing" "app_services" {
#   tier          = "Standard"
#   resource_type = "AppServices"
# }
#
# resource "azurerm_security_center_subscription_pricing" "sql_servers" {
#   tier          = "Standard"
#   resource_type = "SqlServers"
# }
#
# resource "azurerm_security_center_subscription_pricing" "storage_accounts" {
#   tier          = "Standard"
#   resource_type = "StorageAccounts"
# }
#
# resource "azurerm_security_center_subscription_pricing" "virtual_machines" {
#   tier          = "Standard"
#   resource_type = "VirtualMachines"
# }

# Azure Sentinel (Security Information and Event Management)
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "main" {
  workspace_id = azurerm_log_analytics_workspace.main.id
}

# Sentinel Data Connectors - Commented out due to onboarding requirements
# resource "azurerm_sentinel_data_connector_azure_active_directory" "aad" {
#   name                       = "azure_active_directory"
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
# }
#
# resource "azurerm_sentinel_data_connector_azure_security_center" "asc" {
#   name                       = "azure_security_center"
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
# }
#
# resource "azurerm_sentinel_data_connector_azure_advanced_threat_protection" "atp" {
#   name                       = "azure_advanced_threat_protection"
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
# }

# Sentinel Analytics Rules - Commented out due to onboarding requirements
# resource "azurerm_sentinel_alert_rule_scheduled" "failed_logins" {
#   name                       = "Failed Login Attempts"
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
#   display_name               = "Failed Login Attempts"
#   description                = "Detects multiple failed login attempts"
#   severity                   = "Medium"
#   enabled                    = true
#   query                      = <<-EOT
#     SigninLogs
#     | where ResultType == "50126"
#     | summarize count() by bin(TimeGenerated, 5m), UserPrincipalName
#     | where count_ > 5
#   EOT
#
#   query_frequency = "PT5M"
#   query_period    = "PT5M"
#   trigger_operator = "GreaterThan"
#   trigger_threshold = 0
# }
#
# resource "azurerm_sentinel_alert_rule_scheduled" "suspicious_activity" {
#   name                       = "Suspicious Activity"
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
#   display_name               = "Suspicious Activity Detection"
#   description                = "Detects suspicious activity patterns"
#   severity                   = "High"
#   enabled                    = true
#   query                      = <<-EOT
#     SecurityEvent
#     | where EventID == 4625
#     | where TimeGenerated > ago(1h)
#     | summarize count() by bin(TimeGenerated, 5m), Computer
#     | where count_ > 10
#   EOT
#
#   query_frequency = "PT5M"
#   query_period    = "PT5M"
#   trigger_operator = "GreaterThan"
#   trigger_threshold = 0
# }

# Note: Workbooks can be created manually in the Azure portal
