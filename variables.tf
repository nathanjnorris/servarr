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
    type = string
}

variable "ssh_username" {
    type = string
}

variable "ssh_private_key_filename" {
    type = string
}

variable "ssh_private_key_value" {
    sensitive = true
    type = string
}

variable "ssh_port" {
    type = number
}
