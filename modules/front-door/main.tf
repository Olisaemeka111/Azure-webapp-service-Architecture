# Azure Front Door module for Azure App Service Architecture

# Front Door Profile
resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = var.front_door_name
  resource_group_name = var.resource_group_name
  sku_name            = "Premium_AzureFrontDoor"

  tags = var.tags
}

# Front Door Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "main" {
  name                     = "${var.front_door_name}-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 50
  }

  health_probe {
    interval_in_seconds = 240
    path                = "/"
    protocol            = "Https"
    request_type        = "HEAD"
  }
}

# Front Door Origin
resource "azurerm_cdn_frontdoor_origin" "app_service" {
  name                          = "${var.front_door_name}-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id

  enabled                        = true
  host_name                      = var.app_service_fqdn
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.app_service_fqdn
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true

  private_link {
    request_message        = "Request access for Private Link Origin CDN Frontdoor"
    target_type           = "sites"
    location              = var.location
    private_link_target_id = var.app_service_private_link_target_id
  }
}

# Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "${var.front_door_name}-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  tags = var.tags
}

# Front Door Route
resource "azurerm_cdn_frontdoor_route" "main" {
  name                          = "${var.front_door_name}-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.app_service.id]

  enabled = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  # cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.main.id]

  link_to_default_domain = true
}

# Front Door Custom Domain - Commented out due to DNS zone availability
# resource "azurerm_cdn_frontdoor_custom_domain" "main" {
#   name                     = "${var.front_door_name}-domain"
#   cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
#   dns_zone_id              = azurerm_dns_zone.main.id
#   host_name                = "${var.front_door_name}.${var.domain_name}"
#
#   tls {
#     certificate_type    = "ManagedCertificate"
#     minimum_tls_version = "TLS12"
#   }
# }
#
# # DNS Zone
# resource "azurerm_dns_zone" "main" {
#   name                = var.domain_name
#   resource_group_name = var.resource_group_name
#
#   tags = var.tags
# }
#
# # DNS A Record
# resource "azurerm_dns_a_record" "main" {
#   name                = var.front_door_name
#   zone_name           = azurerm_dns_zone.main.name
#   resource_group_name = var.resource_group_name
#   ttl                 = 300
#   target_resource_id  = azurerm_cdn_frontdoor_endpoint.main.id
#
#   tags = var.tags
# }

# Front Door Security Policy (WAF) - Commented out due to custom domain dependency
# resource "azurerm_cdn_frontdoor_security_policy" "main" {
#   name                     = "${var.front_door_name}-security-policy"
#   cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
#
#   security_policies {
#     firewall {
#       cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.main.id
#
#       association {
#         domain {
#           cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.main.id
#         }
#         patterns_to_match = ["/*"]
#       }
#     }
#   }
# }

# Front Door Firewall Policy (WAF Rules)
resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
  name                              = "wafpolicy"
  resource_group_name               = var.resource_group_name
  sku_name                          = azurerm_cdn_frontdoor_profile.main.sku_name
  enabled                           = var.waf_enabled
  mode                              = var.waf_mode
  redirect_url                      = "https://www.example.com"
  custom_block_response_status_code = 403
  custom_block_response_body        = base64encode("Access Denied")

  custom_rule {
    name                           = "RateLimitRule"
    enabled                        = true
    priority                       = 1
    rate_limit_duration_in_minutes = 1
    rate_limit_threshold           = 10
    type                           = "RateLimitRule"
    action                         = "Block"

    match_condition {
      match_variable     = "RemoteAddr"
      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.0/24", "10.0.0.0/24"]
    }
  }

  custom_rule {
    name     = "GeoBlockRule"
    enabled  = true
    priority = 2
    type     = "MatchRule"
    action   = "Block"

    match_condition {
      match_variable     = "RemoteAddr"
      operator           = "GeoMatch"
      negation_condition = false
      match_values       = ["US", "CA"]
    }
  }

  managed_rule {
    type    = "DefaultRuleSet"
    version = "1.0"
    action  = "Block"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }

  tags = var.tags
}
