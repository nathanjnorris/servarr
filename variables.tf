variable "cloudflare_api_token"{
}

variable "github_access_token" {
}

variable "zone_id" {
}

variable "zone" {
}

variable "account_id" {
}

variable "ssh_host" {
    sensitive = true
    type = string
}

variable "ssh_username" {
    sensitive = true
    type = string
}

variable "ssh_private_key" {
    sensitive = true
    type = string
}

variable "ssh_port" {
    sensitive = true
    type = number
}
