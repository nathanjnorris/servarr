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
    security_level           = "high"
    challenge_ttl            = 7200
  }
}

###
# DNS records
###

# Create a CNAME record that routes servarr.nathanjn.com to the tunnel.
resource "cloudflare_record" "servarr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "servarr"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "plex_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "plex"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "overseerr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "overseerr"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "sonarr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "sonarr"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "sonarr4k_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "4ksonarr"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "radarr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "radarr"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "radarr4k_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "4kradarr"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "bazarr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "bazarr"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "bazarr4k_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "4kbazarr"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "prowlarr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "prowlarr"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "qbittorrent_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "qbittorrent"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "tautulli_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "tautulli"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "wizarr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "wizarr"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "maintainerr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "maintainerr"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "maintainerr4k_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "4kmaintainerr"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "kopia_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "kopia"
  value   = cloudflare_tunnel.servarr_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "monitor_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "monitor"
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
      hostname = "servarr.nathanjn.com"
      service  = "ssh://172.17.0.1"
    }
    ingress_rule {
      hostname = "plex.nathanjn.com"
      service  = "http://plex:32400"
    }
    ingress_rule {
      hostname = "overseerr.nathanjn.com"
      service  = "http://overseerr:5055"
    }
    ingress_rule {
      hostname = "sonarr.nathanjn.com"
      service  = "http://gluetun:8989"
    }
    ingress_rule {
      hostname = "4ksonarr.nathanjn.com"
      service  = "http://gluetun:8988"
    }
    ingress_rule {
      hostname = "radarr.nathanjn.com"
      service  = "http://gluetun:7878"
    }
    ingress_rule {
      hostname = "4kradarr.nathanjn.com"
      service  = "http://gluetun:7877"
    }
    ingress_rule {
      hostname = "bazarr.nathanjn.com"
      service  = "http://gluetun:6767"
    }
    ingress_rule {
      hostname = "4kbazarr.nathanjn.com"
      service  = "http://gluetun:6766"
    }
    ingress_rule {
      hostname = "prowlarr.nathanjn.com"
      service  = "http://gluetun:9696"
    }
    ingress_rule {
      hostname = "qbittorrent.nathanjn.com"
      service  = "http://gluetun:8080"
    }
    ingress_rule {
      hostname = "tautulli.nathanjn.com"
      service  = "http://tautulli:8181"
    }
    ingress_rule {
      hostname = "wizarr.nathanjn.com"
      service  = "http://wizarr:5690"
    }
    ingress_rule {
      hostname = "maintainerr.nathanjn.com"
      service  = "http://maintainerr:6246"
    }
    ingress_rule {
      hostname = "4kmaintainerr.nathanjn.com"
      service  = "http://4kmaintainerr:6246"
    }
    ingress_rule {
      hostname = "kopia.nathanjn.com"
      service  = "http://kopia:51515"
    }
    ingress_rule {
      hostname = "monitor.nathanjn.com"
      service  = "http://uptime-kuma:3001"
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
# Bot management
### 

resource "cloudflare_bot_management" "bots_nathanjn_com" {
  zone_id    = data.cloudflare_zone.nathanjn_com.id
  fight_mode = true
  enable_js  = true
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
  name             = "servarr.nathanjn.com"
  domain           = "servarr.nathanjn.com"
  session_duration = "2h"
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

resource "cloudflare_access_application" "sonarr_nathanjn_com" {
  zone_id          = data.cloudflare_zone.nathanjn_com.id
  name             = "sonarr.nathanjn.com"
  domain           = "sonarr.nathanjn.com"
  session_duration = "2h"
}

resource "cloudflare_access_policy" "user_sonarr" {
  application_id = cloudflare_access_application.sonarr_nathanjn_com.id
  zone_id        = data.cloudflare_zone.nathanjn_com.id
  name           = "User auth"
  precedence     = "1"
  decision       = "allow"
  include {
    email = ["nathanjamesnorris@gmail.com"]
  }
}

resource "cloudflare_access_application" "sonarr4k_nathanjn_com" {
  zone_id          = data.cloudflare_zone.nathanjn_com.id
  name             = "4ksonarr.nathanjn.com"
  domain           = "4ksonarr.nathanjn.com"
  session_duration = "2h"
}

resource "cloudflare_access_policy" "user_sonarr4k" {
  application_id = cloudflare_access_application.sonarr4k_nathanjn_com.id
  zone_id        = data.cloudflare_zone.nathanjn_com.id
  name           = "User auth"
  precedence     = "1"
  decision       = "allow"
  include {
    email = ["nathanjamesnorris@gmail.com"]
  }
}

resource "cloudflare_access_application" "radarr_nathanjn_com" {
  zone_id          = data.cloudflare_zone.nathanjn_com.id
  name             = "radarr.nathanjn.com"
  domain           = "radarr.nathanjn.com"
  session_duration = "2h"
}

resource "cloudflare_access_policy" "user_radarr" {
  application_id = cloudflare_access_application.radarr_nathanjn_com.id
  zone_id        = data.cloudflare_zone.nathanjn_com.id
  name           = "User auth"
  precedence     = "1"
  decision       = "allow"
  include {
    email = ["nathanjamesnorris@gmail.com"]
  }
}

resource "cloudflare_access_application" "radarr4k_nathanjn_com" {
  zone_id          = data.cloudflare_zone.nathanjn_com.id
  name             = "4kradarr.nathanjn.com"
  domain           = "4kradarr.nathanjn.com"
  session_duration = "2h"
}

resource "cloudflare_access_policy" "user_radarr4k" {
  application_id = cloudflare_access_application.radarr4k_nathanjn_com.id
  zone_id        = data.cloudflare_zone.nathanjn_com.id
  name           = "User auth"
  precedence     = "1"
  decision       = "allow"
  include {
    email = ["nathanjamesnorris@gmail.com"]
  }
}

resource "cloudflare_access_application" "bazarr_nathanjn_com" {
  zone_id          = data.cloudflare_zone.nathanjn_com.id
  name             = "bazarr.nathanjn.com"
  domain           = "bazarr.nathanjn.com"
  session_duration = "2h"
}

resource "cloudflare_access_policy" "user_bazarr" {
  application_id = cloudflare_access_application.bazarr_nathanjn_com.id
  zone_id        = data.cloudflare_zone.nathanjn_com.id
  name           = "User auth"
  precedence     = "1"
  decision       = "allow"
  include {
    email = ["nathanjamesnorris@gmail.com"]
  }
}

resource "cloudflare_access_application" "bazarr4k_nathanjn_com" {
  zone_id          = data.cloudflare_zone.nathanjn_com.id
  name             = "4kbazarr.nathanjn.com"
  domain           = "4kbazarr.nathanjn.com"
  session_duration = "2h"
}

resource "cloudflare_access_policy" "user_bazarr4k" {
  application_id = cloudflare_access_application.bazarr4k_nathanjn_com.id
  zone_id        = data.cloudflare_zone.nathanjn_com.id
  name           = "User auth"
  precedence     = "1"
  decision       = "allow"
  include {
    email = ["nathanjamesnorris@gmail.com"]
  }
}

resource "cloudflare_access_application" "prowlarr_nathanjn_com" {
  zone_id          = data.cloudflare_zone.nathanjn_com.id
  name             = "prowlarr.nathanjn.com"
  domain           = "prowlarr.nathanjn.com"
  session_duration = "2h"
}

resource "cloudflare_access_policy" "user_prowlarr" {
  application_id = cloudflare_access_application.prowlarr_nathanjn_com.id
  zone_id        = data.cloudflare_zone.nathanjn_com.id
  name           = "User auth"
  precedence     = "1"
  decision       = "allow"
  include {
    email = ["nathanjamesnorris@gmail.com"]
  }
}

resource "cloudflare_access_application" "qbittorrent_nathanjn_com" {
  zone_id          = data.cloudflare_zone.nathanjn_com.id
  name             = "qbittorrent.nathanjn.com"
  domain           = "qbittorrent.nathanjn.com"
  session_duration = "2h"
}

resource "cloudflare_access_policy" "user_qbittorrent" {
  application_id = cloudflare_access_application.qbittorrent_nathanjn_com.id
  zone_id        = data.cloudflare_zone.nathanjn_com.id
  name           = "User auth"
  precedence     = "1"
  decision       = "allow"
  include {
    email = ["nathanjamesnorris@gmail.com"]
  }
}

resource "cloudflare_access_application" "tautulli_nathanjn_com" {
  zone_id          = data.cloudflare_zone.nathanjn_com.id
  name             = "tautulli.nathanjn.com"
  domain           = "tautulli.nathanjn.com"
  session_duration = "2h"
}

resource "cloudflare_access_policy" "user_tautulli" {
  application_id = cloudflare_access_application.tautulli_nathanjn_com.id
  zone_id        = data.cloudflare_zone.nathanjn_com.id
  name           = "User auth"
  precedence     = "1"
  decision       = "allow"
  include {
    email = ["nathanjamesnorris@gmail.com"]
  }
}

resource "cloudflare_access_application" "maintainerr_nathanjn_com" {
  zone_id          = data.cloudflare_zone.nathanjn_com.id
  name             = "maintainerr.nathanjn.com"
  domain           = "maintainerr.nathanjn.com"
  session_duration = "2h"
}

resource "cloudflare_access_policy" "user_maintainerr" {
  application_id = cloudflare_access_application.maintainerr_nathanjn_com.id
  zone_id        = data.cloudflare_zone.nathanjn_com.id
  name           = "User auth"
  precedence     = "1"
  decision       = "allow"
  include {
    email = ["nathanjamesnorris@gmail.com"]
  }
}

resource "cloudflare_access_application" "maintainerr4k_nathanjn_com" {
  zone_id          = data.cloudflare_zone.nathanjn_com.id
  name             = "4kmaintainerr.nathanjn.com"
  domain           = "4kmaintainerr.nathanjn.com"
  session_duration = "2h"
}

resource "cloudflare_access_policy" "user_maintainerr4k" {
  application_id = cloudflare_access_application.maintainerr4k_nathanjn_com.id
  zone_id        = data.cloudflare_zone.nathanjn_com.id
  name           = "User auth"
  precedence     = "1"
  decision       = "allow"
  include {
    email = ["nathanjamesnorris@gmail.com"]
  }
}

resource "cloudflare_access_application" "kopia_nathanjn_com" {
  zone_id          = data.cloudflare_zone.nathanjn_com.id
  name             = "kopia.nathanjn.com"
  domain           = "kopia.nathanjn.com"
  session_duration = "2h"
}

resource "cloudflare_access_policy" "user_kopia" {
  application_id = cloudflare_access_application.kopia_nathanjn_com.id
  zone_id        = data.cloudflare_zone.nathanjn_com.id
  name           = "User auth"
  precedence     = "1"
  decision       = "allow"
  include {
    email = ["nathanjamesnorris@gmail.com"]
  }
}

resource "cloudflare_access_application" "monitor_nathanjn_com" {
  zone_id          = data.cloudflare_zone.nathanjn_com.id
  name             = "monitor.nathanjn.com"
  domain           = "monitor.nathanjn.com"
  session_duration = "2h"
}

resource "cloudflare_access_policy" "user_monitor" {
  application_id = cloudflare_access_application.monitor_nathanjn_com.id
  zone_id        = data.cloudflare_zone.nathanjn_com.id
  name           = "User auth"
  precedence     = "1"
  decision       = "allow"
  include {
    email = ["nathanjamesnorris@gmail.com"]
  }
}

###
# R2 (S3-compatible storage)
###

resource "cloudflare_r2_bucket" "bucket-servarr" {
  account_id = var.account_id
  name       = "servarr"
  location   = "WNAM"
}