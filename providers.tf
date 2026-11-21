terraform {
  required_version = ">= 1.17.0, < 2.0.0"

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "nathanjnorris-org"
    workspaces {
      name = "servarr"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.29"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.13.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "github" {
  token = var.github_access_token
}

provider "random" {
}
