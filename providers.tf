terraform {
  required_version = "~> 1.7.0"

  cloud {
    organization = "nathanjnorris-org"

    workspaces {
      name = "servarr"
    }
  }
  
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
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "github" {
  token = var.github_access_token
}

provider "random" {
}
