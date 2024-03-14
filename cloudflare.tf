###
# This Terraform file is a based on mythofechelon's guide to exposing a Plex server via Cloudlare tunnels: 
# https://mythofechelon.co.uk/blog/2024/1/7/how-to-set-up-free-secure-high-quality-remote-access-for-plex 
###


###
# Zone configuration 
###

# Create a zone
data "cloudflare_zone" "nathanjn_com" {
  name = "nathanjn.com"
}

# Create a CNAME record that routes plex.nathanjn.com to the tunnel.
resource "cloudflare_record" "plex_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "plex"
  value   = "${cloudflare_tunnel.servarr_tunnel.cname}"
  type    = "CNAME"
  proxied = true
}

# Create a CNAME record that routes ssh.nathanjn.com to the tunnel.
resource "cloudflare_record" "ssh_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "ssh"
  value   = "${cloudflare_tunnel.servarr_tunnel.cname}"
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
resource "cloudflare_tunnel_config" "servarr_tunnel_plex" {
  tunnel_id = cloudflare_tunnel.servarr_tunnel.id
  account_id = var.account_id
  config {
   ingress_rule {
     hostname = "plex.nathanjn.com"
     service  = "http://plex:32400"
   }
    ingress_rule {
     hostname = "ssh.nathanjn.com/servarr"
     service  = "ssh://172.17.0.1:22"
   }
   ingress_rule {
     service  = "http_status:404"
   }
  }
}

###
# Cache configuration 
###

# Bypass the cache
resource "cloudflare_ruleset" "nathanjn_com" {
  zone_id     = data.cloudflare_zone.nathanjn_com.id
  name        = "Cache Bypass Ruleset"
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
# Bot management 
###

# Enable the free tier of bot management

resource "cloudflare_bot_management" "nathanjn_com" {
  zone_id    = data.cloudflare_zone.nathanjn_com.id
  fight_mode = true
}

###
# Zero Trust 
###

# Create an Access application to control who can connect to SSH.
resource "cloudflare_access_application" "ssh_nathanjn_com" {
  zone_id          = data.cloudflare_zone.nathanjn_com.id
  name             = "Access application for ssh.nathanjn.com"
  domain           = "ssh.nathanjn.com"
  session_duration = "4h"
}

# Creates an Access policy for SSH.
resource "cloudflare_access_policy" "ssh_nathanjn_com" {
  application_id = cloudflare_access_application.ssh_nathanjn_com.id
  zone_id        = data.cloudflare_zone.nathanjn_com.id
  name           = "Access policy for ssh.nathanjn.com"
  precedence     = "1"
  decision       = "allow"
  include {
    email = ["nathanjamesnorris@gmail.com"]
  }
}