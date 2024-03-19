resource "github_actions_secret" "servar_tunnel_token" {
  repository      = "servarr"
  secret_name     = "servarr_tunnel_token"
  encrypted_value = "${cloudflare_tunnel.servarr_tunnel.tunnel_token}"
}

resource "github_actions_secret" "service_token_id" {
  repository      = "servarr"
  secret_name     = "servarr_token_id"
  plaintext_value = "${cloudflare_access_service_token.github_actions.client_id}"
}

resource "github_actions_secret" "service_token_secret" {
  repository      = "servarr"
  secret_name     = "servarr_token_secret"
  encrypted_value = "${cloudflare_access_service_token.github_actions.client_secret}"
}

resource "github_actions_secret" "ssh_private_key_value" {
  repository      = "servarr"
  secret_name     = "ssh_private_key"
  plaintext_value = var.ssh_private_key_value
}

resource "github_actions_secret" "ssh_host" {
  repository      = "servarr"
  secret_name     = "ssh_host"
  plaintext_value = var.ssh_host
}

resource "github_actions_secret" "ssh_username" {
  repository      = "servarr"
  secret_name     = "ssh_username"
  plaintext_value = var.ssh_username
}

resource "github_actions_secret" "ssh_private_key_filename" {
  repository      = "servarr"
  secret_name     = "ssh_private_key_filename"
  plaintext_value = var.ssh_private_key_filename
}



resource "github_actions_secret" "ssh_port" {
  repository      = "servarr"
  secret_name     = "ssh_port"
  plaintext_value = var.ssh_port
}

