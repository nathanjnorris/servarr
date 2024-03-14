terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
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
  required_version = ">= 0.13"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "random" {
}

provider "github" {
    token = var.github_access_token
}