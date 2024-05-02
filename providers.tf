terraform {
  required_version = "~> 1.8.2"

  backend "remote" {
    hostname = "nathanjnorris-org"
    workspaces {
      name = "servarr"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.30.0"
    }
    random = {
      source = "hashicorp/random"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.2.1"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.27.0"
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

provider "google" {
  project = var.gcp_project_id
}