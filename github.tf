resource "github_actions_secret" "servar_tunnel_token" {
  repository      = "servarr"
  secret_name     = "servarr_tunnel_token"
  encrypted_value = "${cloudflare_tunnel.servarr_tunnel.tunnel_token}"
}

resource "github_actions_secret" "ssh_host" {
  repository      = "servarr"
  secret_name     = "ssh_host"
  encrypted_value = var.ssh_host
}


resource "github_actions_secret" "ssh_username" {
  repository      = "servarr"
  secret_name     = "ssh_username"
  encrypted_value = var.ssh_username
}

resource "github_actions_secret" "ssh_private_key" {
  repository      = "servarr"
  secret_name     = "ssh_private_key"
  encrypted_value = var.ssh_private_key
}

resource "github_actions_secret" "ssh_port" {
  repository      = "servarr"
  secret_name     = "ssh_private_key"
  encrypted_value = var.ssh_port
}

