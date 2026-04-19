output "servarr_tunnel_token" {
  value       = cloudflare_tunnel.servarr_tunnel.tunnel_token
  description = "Token used by a connector to authenticate and run the tunnel."
  sensitive   = true
}
output "google_assistant_client_id" {
  value       = cloudflare_access_service_token.google_assistant.client_id
  description = "Client ID for Google Assistant service token."
  sensitive   = true
}

output "google_assistant_client_secret" {
  value       = cloudflare_access_service_token.google_assistant.client_secret
  description = "Client secret for Google Assistant service token."
  sensitive   = true
}