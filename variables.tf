variable "cloudflare_api_token" {
  type        = string
  description = "Token for Terraform provider to work with the Cloudflare API"
  sensitive   = true
}

variable "github_access_token" {
  type        = string
  description = "Personal access token for Terraform provider to act on user behalf"
  sensitive   = true
}

variable "account_id" {
  type        = string
  description = "The account identifier, the basic resource for working with Cloudflare zones, teams and users"
}

# variable "ssh_host" {
#   type        = string
#   description = "The hostname of the server"
# }

# variable "ssh_port" {
#   type        = number
#   description = "The SSH port of the server"
# }

variable "ssh_username" {
  type        = string
  description = "The username used for authentication"
}

variable "ssh_private_key_filename" {
  type        = string
  description = "The filename of the private key used for authentication"
}

variable "ssh_private_key_value" {
  type        = string
  description = "The value of the private key used for authentication"
  sensitive   = true
}

variable "gluetun_private_key" {
  type        = string
  description = "The private key used for gluetun VPN provider"
  sensitive   = true
}

variable "gluetun_preshared_key" {
  type        = string
  description = "The preshared key used for gluetun VPN provider"
  sensitive   = true
}

variable "sudo_password" {
  type        = string
  description = "The password of the permitted user, to execute a command as the superuser"
  sensitive   = true
}

variable "kopia_password" {
  type        = string
  description = "The password used for Kopia"
  sensitive   = true
}

variable "tailscale_client_id" {
  type        = string
  description = "The GitHub Actions client ID for Tailscale OAuth"
  sensitive   = true
}

variable "tailscale_client_secret" {
  type        = string
  description = "The GitHub Actions client secret for Tailscale OAuth"
  sensitive   = true
}

variable "gluetun_wireguard_address" {
  type        = string
  description = "The WireGuard address for gluetun VPN"
  sensitive   = true
}

variable "gluetun_port" {
  type        = number
  description = "The port used for torrenting"
  sensitive   = true
}

variable "tailscale_client_secret_exit_node" {
  type        = string
  description = "The exit node client secret for Tailscale OAuth"
  sensitive   = true
}