output "servarr_tunnel_token" {
  value = cloudflare_tunnel.servarr_tunnel.tunnel_token
  sensitive = true
}