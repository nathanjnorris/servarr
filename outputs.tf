output "servarr_tunnel_token" {
  value       = cloudflare_tunnel.servarr_tunnel.tunnel_token
  description = "Token used by a connector to authenticate and run the tunnel."
  sensitive   = true
}

output "r2_secret_access_token" {
  value       = module.r2-api-token.secret
  description = "Token used by a connector to authenticate and run the tunnel."
  sensitive   = true
}