terraform {
  # backend "remote" {
  #   hostname     = "app.terraform.io"
  #   organization = "nathanjnorris-org"
  #   workspaces {
  #     name = "servarr"
  #   }
  # }
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.9.0"
    }
    random = {
      source = "hashicorp/random"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
  required_version = "~> 1.7.0"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "github" {
  token = var.github_access_token
}

provider "random" {
}
