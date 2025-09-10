# Outputs for Front Door module

output "front_door_id" {
  description = "ID of the Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.main.id
}

output "front_door_name" {
  description = "Name of the Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.main.name
}

output "front_door_fqdn" {
  description = "FQDN of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.main.host_name
}

output "front_door_url" {
  description = "URL of the Front Door endpoint"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.main.host_name}"
}

# Custom domain outputs - Commented out due to resource being disabled
# output "custom_domain_name" {
#   description = "Name of the custom domain"
#   value       = azurerm_cdn_frontdoor_custom_domain.main.host_name
# }
#
# output "custom_domain_url" {
#   description = "URL of the custom domain"
#   value       = "https://${azurerm_cdn_frontdoor_custom_domain.main.host_name}"
# }
#
# output "dns_zone_name" {
#   description = "Name of the DNS zone"
#   value       = azurerm_dns_zone.main.name
# }

output "waf_policy_id" {
  description = "ID of the WAF policy"
  value       = azurerm_cdn_frontdoor_firewall_policy.main.id
}

output "waf_policy_name" {
  description = "Name of the WAF policy"
  value       = azurerm_cdn_frontdoor_firewall_policy.main.name
}
