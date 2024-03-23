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

variable "ssh_host" {
  type        = string
  description = "The hostname of the server"
}

variable "ssh_port" {
  type        = number
  description = "The SSH port of the server"
}

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

variable "mullvad_private_key" {
  type        = string
  description = "The base64 encoded value of the private key used for the Mullvad VPN"
  sensitive   = true
}