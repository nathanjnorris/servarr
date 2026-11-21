resource "github_actions_secret" "servar_tunnel_token" {
  repository  = "servarr"
  secret_name = "servarr_tunnel_token"
  value       = cloudflare_tunnel.servarr_tunnel.tunnel_token
}

resource "github_actions_secret" "home_assistant_dns_token" {
  repository  = "servarr"
  secret_name = "home_assistant_dns_token"
  value       = cloudflare_api_token.home_assistant_dns.value
}

# resource "github_actions_variable" "service_token_id" {
#   repository    = "servarr"
#   variable_name = "service_token_id"
#   value         = cloudflare_access_service_token.github_actions.client_id
# }

# resource "github_actions_secret" "service_token_secret" {
#   repository      = "servarr"
#   secret_name     = "service_token_secret"
#   plaintext_value = cloudflare_access_service_token.github_actions.client_secret
# }

# resource "github_actions_variable" "ssh_host" {
#   repository    = "servarr"
#   variable_name = "ssh_host"
#   value         = var.ssh_host
# }

# resource "github_actions_variable" "ssh_port" {
#   repository    = "servarr"
#   variable_name = "ssh_port"
#   value         = var.ssh_port
# }

resource "github_actions_variable" "ssh_username" {
  repository    = "servarr"
  variable_name = "ssh_username"
  value         = var.ssh_username
}

resource "github_actions_variable" "ssh_private_key_filename" {
  repository    = "servarr"
  variable_name = "ssh_private_key_filename"
  value         = var.ssh_private_key_filename
}

resource "github_actions_secret" "ssh_private_key_value" {
  repository  = "servarr"
  secret_name = "ssh_private_key_value"
  value       = var.ssh_private_key_value
}

resource "github_actions_secret" "sudo_password" {
  repository  = "servarr"
  secret_name = "sudo_password"
  value       = var.sudo_password
}

resource "github_actions_secret" "kopia_password" {
  repository  = "servarr"
  secret_name = "kopia_password"
  value       = var.kopia_password
}

resource "github_actions_secret" "gluetun_private_key" {
  repository  = "servarr"
  secret_name = "gluetun_private_key"
  value       = var.gluetun_private_key
}

resource "github_actions_secret" "gluetun_preshared_key" {
  repository  = "servarr"
  secret_name = "gluetun_preshared_key"
  value       = var.gluetun_preshared_key
}

resource "github_actions_secret" "tailscale_client_id" {
  repository  = "servarr"
  secret_name = "ts_oauth_client_id"
  value       = var.tailscale_client_id
}

resource "github_actions_secret" "tailscale_client_secret" {
  repository  = "servarr"
  secret_name = "ts_oauth_secret"
  value       = var.tailscale_client_secret
}

resource "github_actions_secret" "gluetun_wireguard_address" {
  repository  = "servarr"
  secret_name = "gluetun_wireguard_address"
  value       = var.gluetun_wireguard_address
}

resource "github_actions_secret" "gluetun_port" {
  repository  = "servarr"
  secret_name = "gluetun_port"
  value       = var.gluetun_port
}

resource "github_actions_secret" "tailscale_client_secret_exit_node" {
  repository  = "servarr"
  secret_name = "ts_client_secret_exit_node"
  value       = var.tailscale_client_secret_exit_node
}