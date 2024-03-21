output "servarr_tunnel_token" {
  value       = cloudflare_tunnel.servarr_tunnel.tunnel_token
  description = "Token used by a connector to authenticate and run the tunnel."
  sensitive   = true
}