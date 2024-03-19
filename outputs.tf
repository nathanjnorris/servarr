output "servarr_tunnel_token" {
  value = cloudflare_tunnel.servarr_tunnel.tunnel_token
  description = "Token used by a connector to authenticate and run the tunnel."
  sensitive = true
}

output "service_token_id" {
  value = cloudflare_access_service_token.github_actions.client_id
  description = "Client ID associated with the Service Token"
}

output "service_token_secret" {
  value = cloudflare_access_service_token.github_actions.client_secret
  description = "A secret for interacting with Access protocols."
  sensitive = true
}