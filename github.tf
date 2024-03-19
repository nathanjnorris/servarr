resource "github_actions_secret" "servar_tunnel_token" {
  repository      = "servarr"
  secret_name     = "servarr_tunnel_token"
  plaintext_value = "${cloudflare_tunnel.servarr_tunnel.tunnel_token}"
}

resource "github_actions_variable" "service_token_id" {
  repository      = "servarr"
  variable_name     = "service_token_id"
  value = "${cloudflare_access_service_token.github_actions.client_id}"
}

resource "github_actions_secret" "service_token_secret" {
  repository      = "servarr"
  secret_name     = "service_token_secret"
  plaintext_value = "${cloudflare_access_service_token.github_actions.client_secret}"
}

resource "github_actions_variable" "ssh_host" {
  repository      = "servarr"
  variable_name     = "ssh_host"
  value = var.ssh_host
}

resource "github_actions_variable" "ssh_port" {
  repository      = "servarr"
  variable_name     = "ssh_port"
  value = var.ssh_port
}

resource "github_actions_secret" "ssh_username" {
  repository      = "servarr"
  secret_name     = "ssh_username"
  plaintext_value = var.ssh_username
}

resource "github_actions_variable" "ssh_private_key_filename" {
  repository      = "servarr"
  variable_name     = "ssh_private_key_filename"
  value = var.ssh_private_key_filename
}

resource "github_actions_secret" "ssh_private_key_value" {
  repository      = "servarr"
  secret_name     = "ssh_private_key_value"
  plaintext_value = var.ssh_private_key_value
}