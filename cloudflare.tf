###
# This Terraform file is a based on mythofechelon's guide to exposing a Plex server via Cloudlare tunnels: 
# https://mythofechelon.co.uk/blog/2024/1/7/how-to-set-up-free-secure-high-quality-remote-access-for-plex 
###


###
# Zone configuration 
###

# Import zone
data "cloudflare_zone" "nathanjn_com" {
  name = "nathanjn.com"
}

# Enable DNSSEC
resource "cloudflare_zone_dnssec" "example" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
}

# Customize zone settings
resource "cloudflare_zone_settings_override" "nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  settings {
    always_use_https         = "on"
    min_tls_version          = "1.2"
    opportunistic_encryption = "on"
    tls_1_3                  = "on"
    automatic_https_rewrites = "on"
  }
}

###
# DNS records
###

# Create a CNAME record that routes plex.nathanjn.com to the tunnel.
resource "cloudflare_record" "plex_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "plex"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

# Create a CNAME record that routes servarr.nathanjn.com to the tunnel.
resource "cloudflare_record" "servarr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "servarr"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

###
# Tunnel configuration 
###

# Generate a secret for the tunnel.
resource "random_password" "servarr_tunnel_secret" {
  length = 64
}

# Create a new locally-managed tunnel for the servarr.
resource "cloudflare_tunnel" "servarr_tunnel" {
  account_id = var.account_id
  name       = "servarr tunnel"
  secret     = base64sha256(random_password.servarr_tunnel_secret.result)
}

# Create the Plex configuration for the tunnel.
resource "cloudflare_tunnel_config" "servarr_tunnel" {
  tunnel_id  = cloudflare_tunnel.servarr_tunnel.id
  account_id = var.account_id
  config {
    ingress_rule {
      hostname = "plex.nathanjn.com"
      service  = "http://plex:32400"
    }
    ingress_rule {
      hostname = "servarr.nathanjn.com"
      service  = "ssh://172.17.0.1"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}

###
# Cache configuration 
###

# Bypass the cache
resource "cloudflare_ruleset" "cache_nathanjn_com" {
  zone_id     = data.cloudflare_zone.nathanjn_com.id
  name        = "Cache bypass"
  description = "Ruleset to bypass cache"
  kind        = "zone"
  phase       = "http_request_cache_settings"

  rules {
    action = "set_cache_settings"
    action_parameters {
      cache = false
      browser_ttl {
        mode = "bypass"
      }
    }
    expression  = "(http.host eq \"plex.nathanjn.com\")"
    description = "Bypass cache for plex.nathanjn.com"
    enabled     = true
  }
}

###
# WAF rules
###

# Challenge bots
resource "cloudflare_ruleset" "bots_nathanjn_com" {
  zone_id     = data.cloudflare_zone.nathanjn_com.id
  name        = "Challenge bots"
  description = "Ruleset to present bots a managed challenge"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules {
    action      = "managed_challenge"
    expression  = "(not cf.client.bot and not http.user_agent contains \"cloudflared\")"
    description = "Present bots a managed challenge (except cloudflared user agent)"
    enabled     = true
  }
}

###
# Zero Trust 
###

# Create an service token for GitHub Actions to authenticate
resource "cloudflare_access_service_token" "github_actions" {
  account_id = var.account_id
  name       = "GitHub Actions"
  duration   = "forever"
}


# Create an Access application to control who can connect to SSH.
resource "cloudflare_access_application" "servarr_nathanjn_com" {
  zone_id          = data.cloudflare_zone.nathanjn_com.id
  name             = "Access application for servarr.nathanjn.com"
  domain           = "servarr.nathanjn.com"
  session_duration = "30m"
  type             = "ssh"
}

# Creates an Access policy for SSH.
resource "cloudflare_access_policy" "service_servarr" {
  application_id = cloudflare_access_application.servarr_nathanjn_com.id
  zone_id        = data.cloudflare_zone.nathanjn_com.id
  name           = "Service auth"
  precedence     = "1"
  decision       = "non_identity"
  include {
    service_token = [cloudflare_access_service_token.github_actions.id]
  }
}

# Creates an Access policy for SSH.
resource "cloudflare_access_policy" "user_servarr" {
  application_id = cloudflare_access_application.servarr_nathanjn_com.id
  zone_id        = data.cloudflare_zone.nathanjn_com.id
  name           = "User auth"
  precedence     = "2"
  decision       = "allow"
  include {
    email = ["nathanjamesnorris@gmail.com"]
  }
}

###
# R2 (S3-compatible storage)
###

resource "cloudflare_r2_bucket" "bucker-servarr" {
  account_id = var.account_id
  name       = "servarr"
  location   = "wnam"
}