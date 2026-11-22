###
# This Terraform file is a based on mythofechelon's guide to exposing a Plex server via Cloudlare tunnels: 
# https://mythofechelon.co.uk/blog/2024/1/7/how-to-set-up-free-secure-high-quality-remote-access-for-plex 
###


###
# Zone configuration 
###

# Import zone
data "cloudflare_zone" "nathanjn_com" {
  filter = {
    name = "nathanjn.com"
  }
}

data "cloudflare_api_token_permission_groups_list" "all" {}

resource "cloudflare_api_token" "home_assistant_dns" {
  name = "home-assistant-traefik-dns"

  policies = [{
    permission_groups = [{ id = one([for pg in data.cloudflare_api_token_permission_groups_list.all.result : pg.id if pg.name == ("DNS Write") && contains(pg.scopes, "com.cloudflare.api.account.zone")]) }, { id = one([for pg in data.cloudflare_api_token_permission_groups_list.all.result : pg.id if pg.name == ("Zone Read") && contains(pg.scopes, "com.cloudflare.api.account.zone")]) }]
    resources = jsonencode({
      "com.cloudflare.api.account.zone.${data.cloudflare_zone.nathanjn_com.id}" = "*"
    })
    effect = "allow"
  }]
}

# Enable DNSSEC
resource "cloudflare_zone_dnssec" "example" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  status  = "active"
}


###
# DNS records
###

# # Create a CNAME record that routes servarr.nathanjn.com to the tunnel.
# resource "cloudflare_record" "servarr_nathanjn_com" {
#   zone_id = data.cloudflare_zone.nathanjn_com.id
#   name    = "servarr"
#   value   = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
#   type    = "CNAME"
#   proxied = true
# }



###
# Tunnel configuration 
###

# Generate a secret for the tunnel.
resource "random_password" "servarr_tunnel_secret" {
  length = 64
}



###
# Cache configuration 
###

# Cache configuration
resource "cloudflare_ruleset" "cache_nathanjn_com" {
  zone_id     = data.cloudflare_zone.nathanjn_com.id
  name        = "Cache bypass"
  description = "Ruleset to bypass cache"
  kind        = "zone"
  phase       = "http_request_cache_settings"


  rules = [
    {
      action      = "set_cache_settings"
      expression  = "(http.host contains \"plex.nathanjn.com\")"
      description = "Bypass cache for plex.nathanjn.com"
      enabled     = true
      action_parameters = {
        cache = false
        browser_ttl = {
          mode = "bypass"
        }
      }
    },
    {
      action      = "set_cache_settings"
      expression  = "(http.request.full_uri wildcard r\"https://nathanjn.com/assets/*\") or (http.request.full_uri wildcard r\"https://consent.nathanjn.com/assets/*\")"
      description = "Cache static assets for nathanjn.com"
      enabled     = true
      action_parameters = {
        cache = true
        cache_key = {
          cache_by_device_type       = true
          cache_deception_armor      = true
          ignore_query_strings_order = true
        }
        edge_ttl = {
          default = 31536000
          mode    = "override_origin"
        }
      }
    }
  ]
}

###
# Custom WAF rules
###

resource "cloudflare_ruleset" "custom_firewall_nathanjn_com" {
  zone_id     = data.cloudflare_zone.nathanjn_com.id
  name        = "Custom WAF rules"
  description = "Custom WAF rules for nathanjn.com"
  kind        = "zone"
  phase       = "http_request_firewall_custom"



  rules = [
    {
      ref         = "challenge_failed_bot_detection"
      description = "Challenge failed bot detection on posts"
      action      = "managed_challenge"
      expression  = "(any(http.request.cookies[\"cf.bot_management.js.detection.passed\"][*] eq \"false\") and http.request.full_uri wildcard r\"https://nathanjn.com/posts/*\" and not cf.client.bot)"
      enabled     = true
    },
    {
      ref         = "require_ha_client_certificate"
      description = "Require mTLS for Home Assistant"
      action      = "block"
      expression  = "((not cf.tls_client_auth.cert_verified or cf.tls_client_auth.cert_revoked) and http.host eq \"ha.nathanjn.com\")"
      enabled     = true
    },
    {
      ref         = "block_selected_user_agents"
      description = "Block AI bots by User Agent"
      action      = "block"
      expression  = "(http.user_agent contains \"Applebot\") or (http.user_agent contains \"bingbot\") or (http.user_agent contains \"ChatGPT-User\") or (http.user_agent contains \"DuckAssistBot\") or (http.user_agent contains \"Googlebot\") or (http.user_agent contains \"meta-externalfetcher\") or (http.user_agent contains \"MistralAI-User\") or (http.user_agent contains \"OAI-SearchBot\") or (http.user_agent contains \"Perplexity-User\") or (http.user_agent contains \"PerplexityBot\") or (http.user_agent contains \"ProRataInc\")"
      enabled     = true
    }
  ]
}

###
# Bot management
### 

resource "cloudflare_bot_management" "bots_nathanjn_com" {
  zone_id    = data.cloudflare_zone.nathanjn_com.id
  fight_mode = true
  enable_js  = true
  # Live value is true (Cloudflare manages robots.txt). v4 did not set it; v5 treats an unset value as false, which would turn it off.
  is_robots_txt_managed = true
}

###
# Zero Trust 
###



# # Create an Access application to control who can connect to SSH.
# resource "cloudflare_access_application" "servarr_nathanjn_com" {
#   zone_id                   = data.cloudflare_zone.nathanjn_com.id
#   name                      = "servarr.nathanjn.com"
#   domain                    = "servarr.nathanjn.com"
#   session_duration          = "2h"
#   type                      = "ssh"
#   auto_redirect_to_identity = true
#   allowed_idps              = ["97ed69f2-279d-4cef-bc29-65b6f7e915bf"]
# }

# # account level
# resource "cloudflare_access_ca_certificate" "servarr" {
#   account_id     = var.account_id
#   application_id = cloudflare_zero_trust_access_application.servarr_nathanjn_com.id
# }


# # Creates an Access policy for SSH.
# resource "cloudflare_access_policy" "service_servarr" {
#   application_id = cloudflare_zero_trust_access_application.servarr_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "Service auth"
#   precedence     = "1"
#   decision       = "non_identity"
#   include {
#     service_token = [cloudflare_zero_trust_access_service_token.github_actions.id]
#   }
# }

# # Creates an Access policy for SSH.
# resource "cloudflare_access_policy" "user_servarr" {
#   application_id = cloudflare_zero_trust_access_application.servarr_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "User auth"
#   precedence     = "2"
#   decision       = "allow"
#   include {
#     email = ["nathan.james.norris@gmail.com"]
#   }
# }


# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "service_sonarr" {
#   application_id = cloudflare_zero_trust_access_application.sonarr_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "Service auth"
#   precedence     = "1"
#   decision       = "non_identity"
#   include {
#     service_token = [cloudflare_zero_trust_access_service_token.uptime_kuma.id]
#   }
# }

removed {
  from = cloudflare_access_policy.service_sonarr
  lifecycle {
    destroy = false
  }
}

# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "user_sonarr" {
#   application_id = cloudflare_zero_trust_access_application.sonarr_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "User auth"
#   precedence     = "2"
#   decision       = "allow"
#   include {
#     email = ["nathan.james.norris@gmail.com"]
#   }
# }

removed {
  from = cloudflare_access_policy.user_sonarr
  lifecycle {
    destroy = false
  }
}


# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "service_sonarr4k" {
#   application_id = cloudflare_zero_trust_access_application.sonarr4k_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "Service auth"
#   precedence     = "1"
#   decision       = "non_identity"
#   include {
#     service_token = [cloudflare_zero_trust_access_service_token.uptime_kuma.id]
#   }
# }

removed {
  from = cloudflare_access_policy.service_sonarr4k
  lifecycle {
    destroy = false
  }
}

# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "user_sonarr4k" {
#   application_id = cloudflare_zero_trust_access_application.sonarr4k_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "User auth"
#   precedence     = "2"
#   decision       = "allow"
#   include {
#     email = ["nathan.james.norris@gmail.com"]
#   }
# }

removed {
  from = cloudflare_access_policy.user_sonarr4k
  lifecycle {
    destroy = false
  }
}


# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "service_radarr" {
#   application_id = cloudflare_zero_trust_access_application.radarr_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "Service auth"
#   precedence     = "1"
#   decision       = "non_identity"
#   include {
#     service_token = [cloudflare_zero_trust_access_service_token.uptime_kuma.id]
#   }
# }

removed {
  from = cloudflare_access_policy.service_radarr
  lifecycle {
    destroy = false
  }
}

# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "user_radarr" {
#   application_id = cloudflare_zero_trust_access_application.radarr_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "User auth"
#   precedence     = "2"
#   decision       = "allow"
#   include {
#     email = ["nathan.james.norris@gmail.com"]
#   }
# }

removed {
  from = cloudflare_access_policy.user_radarr
  lifecycle {
    destroy = false
  }
}


# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "service_radarr4k" {
#   application_id = cloudflare_zero_trust_access_application.radarr4k_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "Service auth"
#   precedence     = "1"
#   decision       = "non_identity"
#   include {
#     service_token = [cloudflare_zero_trust_access_service_token.uptime_kuma.id]
#   }
# }

removed {
  from = cloudflare_access_policy.service_radarr4k
  lifecycle {
    destroy = false
  }
}

# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "user_radarr4k" {
#   application_id = cloudflare_zero_trust_access_application.radarr4k_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "User auth"
#   precedence     = "2"
#   decision       = "allow"
#   include {
#     email = ["nathan.james.norris@gmail.com"]
#   }
# }

removed {
  from = cloudflare_access_policy.user_radarr4k
  lifecycle {
    destroy = false
  }
}


# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "service_bazarr" {
#   application_id = cloudflare_zero_trust_access_application.bazarr_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "Service auth"
#   precedence     = "1"
#   decision       = "non_identity"
#   include {
#     service_token = [cloudflare_zero_trust_access_service_token.uptime_kuma.id]
#   }
# }

removed {
  from = cloudflare_access_policy.service_bazarr
  lifecycle {
    destroy = false
  }
}

# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "user_bazarr" {
#   application_id = cloudflare_zero_trust_access_application.bazarr_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "User auth"
#   precedence     = "2"
#   decision       = "allow"
#   include {
#     email = ["nathan.james.norris@gmail.com"]
#   }
# }

removed {
  from = cloudflare_access_policy.user_bazarr
  lifecycle {
    destroy = false
  }
}


# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "service_bazarr4k" {
#   application_id = cloudflare_zero_trust_access_application.bazarr4k_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "Service auth"
#   precedence     = "1"
#   decision       = "non_identity"
#   include {
#     service_token = [cloudflare_zero_trust_access_service_token.uptime_kuma.id]
#   }
# }

removed {
  from = cloudflare_access_policy.service_bazarr4k
  lifecycle {
    destroy = false
  }
}


# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "user_bazarr4k" {
#   application_id = cloudflare_zero_trust_access_application.bazarr4k_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "User auth"
#   precedence     = "2"
#   decision       = "allow"
#   include {
#     email = ["nathan.james.norris@gmail.com"]
#   }
# }

removed {
  from = cloudflare_access_policy.user_bazarr4k
  lifecycle {
    destroy = false
  }
}


# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "service_prowlarr" {
#   application_id = cloudflare_zero_trust_access_application.prowlarr_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "Service auth"
#   precedence     = "1"
#   decision       = "non_identity"
#   include {
#     service_token = [cloudflare_zero_trust_access_service_token.uptime_kuma.id]
#   }
# }

removed {
  from = cloudflare_access_policy.service_prowlarr
  lifecycle {
    destroy = false
  }
}

# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "user_prowlarr" {
#   application_id = cloudflare_zero_trust_access_application.prowlarr_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "User auth"
#   precedence     = "2"
#   decision       = "allow"
#   include {
#     email = ["nathan.james.norris@gmail.com"]
#   }
# }

removed {
  from = cloudflare_access_policy.user_prowlarr
  lifecycle {
    destroy = false
  }
}


# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "service_qbittorrent" {
#   application_id = cloudflare_zero_trust_access_application.qbittorrent_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "Service auth"
#   precedence     = "1"
#   decision       = "non_identity"
#   include {
#     service_token = [cloudflare_zero_trust_access_service_token.uptime_kuma.id]
#   }
# }

removed {
  from = cloudflare_access_policy.service_qbittorrent
  lifecycle {
    destroy = false
  }
}

# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "user_qbittorrent" {
#   application_id = cloudflare_zero_trust_access_application.qbittorrent_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "User auth"
#   precedence     = "2"
#   decision       = "allow"
#   include {
#     email = ["nathan.james.norris@gmail.com"]
#   }
# }

removed {
  from = cloudflare_access_policy.user_qbittorrent
  lifecycle {
    destroy = false
  }
}


# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "service_tautulli" {
#   application_id = cloudflare_zero_trust_access_application.tautulli_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "Service auth"
#   precedence     = "1"
#   decision       = "non_identity"
#   include {
#     service_token = [cloudflare_zero_trust_access_service_token.uptime_kuma.id]
#   }
# }

removed {
  from = cloudflare_access_policy.service_tautulli
  lifecycle {
    destroy = false
  }
}

# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "user_tautulli" {
#   application_id = cloudflare_zero_trust_access_application.tautulli_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "User auth"
#   precedence     = "2"
#   decision       = "allow"
#   include {
#     email = ["nathan.james.norris@gmail.com"]
#   }
# }

removed {
  from = cloudflare_access_policy.user_tautulli
  lifecycle {
    destroy = false
  }
}


# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "service_maintainerr" {
#   application_id = cloudflare_zero_trust_access_application.maintainerr_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "Service auth"
#   precedence     = "1"
#   decision       = "non_identity"
#   include {
#     service_token = [cloudflare_zero_trust_access_service_token.uptime_kuma.id]
#   }
# }

removed {
  from = cloudflare_access_policy.service_maintainerr
  lifecycle {
    destroy = false
  }
}

# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "user_maintainerr" {
#   application_id = cloudflare_zero_trust_access_application.maintainerr_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "User auth"
#   precedence     = "2"
#   decision       = "allow"
#   include {
#     email = ["nathan.james.norris@gmail.com"]
#   }
# }

removed {
  from = cloudflare_access_policy.user_maintainerr
  lifecycle {
    destroy = false
  }
}


# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "user_kopia" {
#   application_id = cloudflare_zero_trust_access_application.kopia_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "User auth"
#   precedence     = "1"
#   decision       = "allow"
#   include {
#     email = ["nathan.james.norris@gmail.com"]
#   }
# }

removed {
  from = cloudflare_access_policy.user_kopia
  lifecycle {
    destroy = false
  }
}



# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "service_matter" {
#   application_id = cloudflare_zero_trust_access_application.matter_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "Service auth"
#   precedence     = "1"
#   decision       = "non_identity"
#   include {
#     service_token = [cloudflare_zero_trust_access_service_token.uptime_kuma.id]
#   }
# }

removed {
  from = cloudflare_access_policy.service_matter
  lifecycle {
    destroy = false
  }
}

# v5 migration phase 1b: the v5 provider has no cloudflare_access_policy schema, so the policy leaves state here
# (destroy = false: the live application-scoped policy is not touched). Original definition kept for the inline-policy conversion:
# resource "cloudflare_access_policy" "user_matter" {
#   application_id = cloudflare_zero_trust_access_application.matter_nathanjn_com.id
#   zone_id        = data.cloudflare_zone.nathanjn_com.id
#   name           = "User auth"
#   precedence     = "2"
#   decision       = "allow"
#   include {
#     email = ["nathan.james.norris@gmail.com"]
#   }
# }

removed {
  from = cloudflare_access_policy.user_matter
  lifecycle {
    destroy = false
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
resource "cloudflare_zone_setting" "nathanjn_com_always_use_https" {
  zone_id    = data.cloudflare_zone.nathanjn_com.id
  setting_id = "always_use_https"
  value      = "on"
}

import {
  to = cloudflare_zone_setting.nathanjn_com_always_use_https
  id = "${data.cloudflare_zone.nathanjn_com.id}/always_use_https"
}

resource "cloudflare_zone_setting" "nathanjn_com_automatic_https_rewrites" {
  zone_id    = data.cloudflare_zone.nathanjn_com.id
  setting_id = "automatic_https_rewrites"
  value      = "on"
}

import {
  to = cloudflare_zone_setting.nathanjn_com_automatic_https_rewrites
  id = "${data.cloudflare_zone.nathanjn_com.id}/automatic_https_rewrites"
}

resource "cloudflare_zone_setting" "nathanjn_com_challenge_ttl" {
  zone_id    = data.cloudflare_zone.nathanjn_com.id
  setting_id = "challenge_ttl"
  value      = 7200
}

import {
  to = cloudflare_zone_setting.nathanjn_com_challenge_ttl
  id = "${data.cloudflare_zone.nathanjn_com.id}/challenge_ttl"
}

resource "cloudflare_zone_setting" "nathanjn_com_http3" {
  zone_id    = data.cloudflare_zone.nathanjn_com.id
  setting_id = "http3"
  value      = "off"
}

import {
  to = cloudflare_zone_setting.nathanjn_com_http3
  id = "${data.cloudflare_zone.nathanjn_com.id}/http3"
}

resource "cloudflare_zone_setting" "nathanjn_com_min_tls_version" {
  zone_id    = data.cloudflare_zone.nathanjn_com.id
  setting_id = "min_tls_version"
  value      = "1.2"
}

import {
  to = cloudflare_zone_setting.nathanjn_com_min_tls_version
  id = "${data.cloudflare_zone.nathanjn_com.id}/min_tls_version"
}

resource "cloudflare_zone_setting" "nathanjn_com_opportunistic_encryption" {
  zone_id    = data.cloudflare_zone.nathanjn_com.id
  setting_id = "opportunistic_encryption"
  value      = "on"
}

import {
  to = cloudflare_zone_setting.nathanjn_com_opportunistic_encryption
  id = "${data.cloudflare_zone.nathanjn_com.id}/opportunistic_encryption"
}

resource "cloudflare_zone_setting" "nathanjn_com_security_level" {
  zone_id    = data.cloudflare_zone.nathanjn_com.id
  setting_id = "security_level"
  value      = "high"
}

import {
  to = cloudflare_zone_setting.nathanjn_com_security_level
  id = "${data.cloudflare_zone.nathanjn_com.id}/security_level"
}

resource "cloudflare_zone_setting" "nathanjn_com_tls_1_3" {
  zone_id    = data.cloudflare_zone.nathanjn_com.id
  setting_id = "tls_1_3"
  value      = "zrt"
}

import {
  to = cloudflare_zone_setting.nathanjn_com_tls_1_3
  id = "${data.cloudflare_zone.nathanjn_com.id}/tls_1_3"
}

removed {
  from = cloudflare_zone_settings_override.nathanjn_com
  lifecycle {
    destroy = false
  }
  # NOTE: The import blocks above are only valid in the root Terraform module.
  # If this file is a child module, move the import blocks to your root
  # module and prefix 'to' with the module path:
  #   to = module.mymod.cloudflare_zone_setting.nathanjn_com_<setting>
}

resource "cloudflare_dns_record" "plex_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "plex"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.plex_nathanjn_com
  to   = cloudflare_dns_record.plex_nathanjn_com
}

resource "cloudflare_dns_record" "overseerr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "overseerr"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.overseerr_nathanjn_com
  to   = cloudflare_dns_record.overseerr_nathanjn_com
}

resource "cloudflare_dns_record" "seerr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "seerr"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.seerr_nathanjn_com
  to   = cloudflare_dns_record.seerr_nathanjn_com
}

resource "cloudflare_dns_record" "sonarr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "sonarr"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.sonarr_nathanjn_com
  to   = cloudflare_dns_record.sonarr_nathanjn_com
}

resource "cloudflare_dns_record" "sonarr4k_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "4ksonarr"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.sonarr4k_nathanjn_com
  to   = cloudflare_dns_record.sonarr4k_nathanjn_com
}

resource "cloudflare_dns_record" "radarr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "radarr"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.radarr_nathanjn_com
  to   = cloudflare_dns_record.radarr_nathanjn_com
}

resource "cloudflare_dns_record" "radarr4k_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "4kradarr"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.radarr4k_nathanjn_com
  to   = cloudflare_dns_record.radarr4k_nathanjn_com
}

resource "cloudflare_dns_record" "bazarr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "bazarr"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.bazarr_nathanjn_com
  to   = cloudflare_dns_record.bazarr_nathanjn_com
}

resource "cloudflare_dns_record" "bazarr4k_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "4kbazarr"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.bazarr4k_nathanjn_com
  to   = cloudflare_dns_record.bazarr4k_nathanjn_com
}

resource "cloudflare_dns_record" "prowlarr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "prowlarr"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.prowlarr_nathanjn_com
  to   = cloudflare_dns_record.prowlarr_nathanjn_com
}

resource "cloudflare_dns_record" "qbittorrent_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "qbittorrent"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.qbittorrent_nathanjn_com
  to   = cloudflare_dns_record.qbittorrent_nathanjn_com
}

resource "cloudflare_dns_record" "tautulli_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "tautulli"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.tautulli_nathanjn_com
  to   = cloudflare_dns_record.tautulli_nathanjn_com
}

resource "cloudflare_dns_record" "wizarr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "wizarr"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.wizarr_nathanjn_com
  to   = cloudflare_dns_record.wizarr_nathanjn_com
}

resource "cloudflare_dns_record" "maintainerr_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "maintainerr"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.maintainerr_nathanjn_com
  to   = cloudflare_dns_record.maintainerr_nathanjn_com
}

resource "cloudflare_dns_record" "kopia_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "kopia"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.kopia_nathanjn_com
  to   = cloudflare_dns_record.kopia_nathanjn_com
}

resource "cloudflare_dns_record" "status_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "status"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.status_nathanjn_com
  to   = cloudflare_dns_record.status_nathanjn_com
}

resource "cloudflare_dns_record" "ha_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "ha"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.ha_nathanjn_com
  to   = cloudflare_dns_record.ha_nathanjn_com
}

resource "cloudflare_dns_record" "matter_nathanjn_com" {
  zone_id = data.cloudflare_zone.nathanjn_com.id
  name    = "matter"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

moved {
  from = cloudflare_record.matter_nathanjn_com
  to   = cloudflare_dns_record.matter_nathanjn_com
}

# Create a new locally-managed tunnel for the servarr.
resource "cloudflare_zero_trust_tunnel_cloudflared" "servarr_tunnel" {
  account_id    = var.account_id
  name          = "servarr tunnel"
  tunnel_secret = base64sha256(random_password.servarr_tunnel_secret.result)
}

moved {
  from = cloudflare_tunnel.servarr_tunnel
  to   = cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel
}

# v5 no longer exposes the connector token on the tunnel resource; read it from the API.
data "cloudflare_zero_trust_tunnel_cloudflared_token" "servarr_tunnel" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id
}

# Create the Plex configuration for the tunnel.
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "servarr_tunnel" {
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.servarr_tunnel.id
  account_id = var.account_id
  config = {
    ingress = [
      {
        hostname = "plex.nathanjn.com"
        service  = "http://plex:32400"
      },
      {
        hostname = "overseerr.nathanjn.com"
        service  = "http://overseerr:5055"
      },
      {
        hostname = "seerr.nathanjn.com"
        service  = "http://overseerr:5055"
      },
      {
        hostname = "sonarr.nathanjn.com"
        service  = "http://gluetun:8989"
      },
      {
        hostname = "4ksonarr.nathanjn.com"
        service  = "http://gluetun:8988"
      },
      {
        hostname = "radarr.nathanjn.com"
        service  = "http://gluetun:7878"
      },
      {
        hostname = "4kradarr.nathanjn.com"
        service  = "http://gluetun:7877"
      },
      {
        hostname = "bazarr.nathanjn.com"
        service  = "http://gluetun:6767"
      },
      {
        hostname = "4kbazarr.nathanjn.com"
        service  = "http://gluetun:6766"
      },
      {
        hostname = "prowlarr.nathanjn.com"
        service  = "http://gluetun:9696"
      },
      {
        hostname = "qbittorrent.nathanjn.com"
        service  = "http://gluetun:8080"
      },
      {
        hostname = "tautulli.nathanjn.com"
        service  = "http://tautulli:8181"
      },
      {
        hostname = "wizarr.nathanjn.com"
        service  = "http://wizarr:5690"
      },
      {
        hostname = "maintainerr.nathanjn.com"
        service  = "http://maintainerr:6246"
      },
      {
        hostname = "kopia.nathanjn.com"
        service  = "http://kopia:51515"
      },
      {
        hostname = "status.nathanjn.com"
        service  = "http://uptime-kuma:3001"
      },
      {
        hostname = "ha.nathanjn.com"
        service  = "https://host.docker.internal:443"
        origin_request = {
          origin_server_name = "ha.nathanjn.com"
          # The live value is an empty string; keep it explicit so v5 does not rewrite it as null.
          http_host_header         = ""
          ca_pool                  = ""
          connect_timeout          = 30
          disable_chunked_encoding = false
          http2_origin             = false
          keep_alive_connections   = 100
          keep_alive_timeout       = 90
          no_happy_eyeballs        = false
          no_tls_verify            = false
          proxy_type               = ""
          tcp_keep_alive           = 30
          tls_timeout              = 10
        }
      },
      {
        hostname = "matter.nathanjn.com"
        service  = "http://host.docker.internal:5580"
      },
      {
        service = "http_status:404"
      }
    ]
  }
}

moved {
  from = cloudflare_tunnel_config.servarr_tunnel
  to   = cloudflare_zero_trust_tunnel_cloudflared_config.servarr_tunnel
}

# Create an service token for GitHub Actions to authenticate
resource "cloudflare_zero_trust_access_service_token" "github_actions" {
  account_id = var.account_id
  name       = "GitHub Actions"
  duration   = "forever"
}

moved {
  from = cloudflare_access_service_token.github_actions
  to   = cloudflare_zero_trust_access_service_token.github_actions
}

# Create a service token for Google Assistant to authenticate with Home Assistant
resource "cloudflare_zero_trust_access_service_token" "google_assistant" {
  account_id = var.account_id
  name       = "Google Assistant"
  duration   = "forever"
}

moved {
  from = cloudflare_access_service_token.google_assistant
  to   = cloudflare_zero_trust_access_service_token.google_assistant
}

resource "cloudflare_zero_trust_access_application" "sonarr_nathanjn_com" {
  zone_id                    = data.cloudflare_zone.nathanjn_com.id
  name                       = "sonarr.nathanjn.com"
  domain                     = "sonarr.nathanjn.com"
  session_duration           = "2h"
  auto_redirect_to_identity  = true
  allowed_idps               = ["97ed69f2-279d-4cef-bc29-65b6f7e915bf"]
  type                       = "self_hosted"
  http_only_cookie_attribute = true

  policies = [
    {
      name       = "User auth"
      decision   = "allow"
      precedence = 1
      include = [
        {
          email = { email = "nathan.james.norris@gmail.com" }
        }
      ]
    }
  ]
}

moved {
  from = cloudflare_access_application.sonarr_nathanjn_com
  to   = cloudflare_zero_trust_access_application.sonarr_nathanjn_com
}

resource "cloudflare_zero_trust_access_application" "sonarr4k_nathanjn_com" {
  zone_id                    = data.cloudflare_zone.nathanjn_com.id
  name                       = "4ksonarr.nathanjn.com"
  domain                     = "4ksonarr.nathanjn.com"
  session_duration           = "2h"
  auto_redirect_to_identity  = true
  allowed_idps               = ["97ed69f2-279d-4cef-bc29-65b6f7e915bf"]
  type                       = "self_hosted"
  http_only_cookie_attribute = true

  policies = [
    {
      name       = "User auth"
      decision   = "allow"
      precedence = 1
      include = [
        {
          email = { email = "nathan.james.norris@gmail.com" }
        }
      ]
    }
  ]
}

moved {
  from = cloudflare_access_application.sonarr4k_nathanjn_com
  to   = cloudflare_zero_trust_access_application.sonarr4k_nathanjn_com
}

resource "cloudflare_zero_trust_access_application" "radarr_nathanjn_com" {
  zone_id                    = data.cloudflare_zone.nathanjn_com.id
  name                       = "radarr.nathanjn.com"
  domain                     = "radarr.nathanjn.com"
  session_duration           = "2h"
  auto_redirect_to_identity  = true
  allowed_idps               = ["97ed69f2-279d-4cef-bc29-65b6f7e915bf"]
  type                       = "self_hosted"
  http_only_cookie_attribute = true

  policies = [
    {
      name       = "User auth"
      decision   = "allow"
      precedence = 1
      include = [
        {
          email = { email = "nathan.james.norris@gmail.com" }
        }
      ]
    }
  ]
}

moved {
  from = cloudflare_access_application.radarr_nathanjn_com
  to   = cloudflare_zero_trust_access_application.radarr_nathanjn_com
}

resource "cloudflare_zero_trust_access_application" "radarr4k_nathanjn_com" {
  zone_id                    = data.cloudflare_zone.nathanjn_com.id
  name                       = "4kradarr.nathanjn.com"
  domain                     = "4kradarr.nathanjn.com"
  session_duration           = "2h"
  auto_redirect_to_identity  = true
  allowed_idps               = ["97ed69f2-279d-4cef-bc29-65b6f7e915bf"]
  type                       = "self_hosted"
  http_only_cookie_attribute = true

  policies = [
    {
      name       = "User auth"
      decision   = "allow"
      precedence = 1
      include = [
        {
          email = { email = "nathan.james.norris@gmail.com" }
        }
      ]
    }
  ]
}

moved {
  from = cloudflare_access_application.radarr4k_nathanjn_com
  to   = cloudflare_zero_trust_access_application.radarr4k_nathanjn_com
}

resource "cloudflare_zero_trust_access_application" "bazarr_nathanjn_com" {
  zone_id                    = data.cloudflare_zone.nathanjn_com.id
  name                       = "bazarr.nathanjn.com"
  domain                     = "bazarr.nathanjn.com"
  session_duration           = "2h"
  auto_redirect_to_identity  = true
  allowed_idps               = ["97ed69f2-279d-4cef-bc29-65b6f7e915bf"]
  type                       = "self_hosted"
  http_only_cookie_attribute = true

  policies = [
    {
      name       = "User auth"
      decision   = "allow"
      precedence = 1
      include = [
        {
          email = { email = "nathan.james.norris@gmail.com" }
        }
      ]
    }
  ]
}

moved {
  from = cloudflare_access_application.bazarr_nathanjn_com
  to   = cloudflare_zero_trust_access_application.bazarr_nathanjn_com
}

resource "cloudflare_zero_trust_access_application" "bazarr4k_nathanjn_com" {
  zone_id                    = data.cloudflare_zone.nathanjn_com.id
  name                       = "4kbazarr.nathanjn.com"
  domain                     = "4kbazarr.nathanjn.com"
  session_duration           = "2h"
  auto_redirect_to_identity  = true
  allowed_idps               = ["97ed69f2-279d-4cef-bc29-65b6f7e915bf"]
  type                       = "self_hosted"
  http_only_cookie_attribute = true

  policies = [
    {
      name       = "User auth"
      decision   = "allow"
      precedence = 1
      include = [
        {
          email = { email = "nathan.james.norris@gmail.com" }
        }
      ]
    }
  ]
}

moved {
  from = cloudflare_access_application.bazarr4k_nathanjn_com
  to   = cloudflare_zero_trust_access_application.bazarr4k_nathanjn_com
}

resource "cloudflare_zero_trust_access_application" "prowlarr_nathanjn_com" {
  zone_id                    = data.cloudflare_zone.nathanjn_com.id
  name                       = "prowlarr.nathanjn.com"
  domain                     = "prowlarr.nathanjn.com"
  session_duration           = "2h"
  auto_redirect_to_identity  = true
  allowed_idps               = ["97ed69f2-279d-4cef-bc29-65b6f7e915bf"]
  type                       = "self_hosted"
  http_only_cookie_attribute = true

  policies = [
    {
      name       = "User auth"
      decision   = "allow"
      precedence = 1
      include = [
        {
          email = { email = "nathan.james.norris@gmail.com" }
        }
      ]
    }
  ]
}

moved {
  from = cloudflare_access_application.prowlarr_nathanjn_com
  to   = cloudflare_zero_trust_access_application.prowlarr_nathanjn_com
}

resource "cloudflare_zero_trust_access_application" "qbittorrent_nathanjn_com" {
  zone_id                    = data.cloudflare_zone.nathanjn_com.id
  name                       = "qbittorrent.nathanjn.com"
  domain                     = "qbittorrent.nathanjn.com"
  session_duration           = "2h"
  auto_redirect_to_identity  = true
  allowed_idps               = ["97ed69f2-279d-4cef-bc29-65b6f7e915bf"]
  type                       = "self_hosted"
  http_only_cookie_attribute = true

  policies = [
    {
      name       = "User auth"
      decision   = "allow"
      precedence = 1
      include = [
        {
          email = { email = "nathan.james.norris@gmail.com" }
        }
      ]
    }
  ]
}

moved {
  from = cloudflare_access_application.qbittorrent_nathanjn_com
  to   = cloudflare_zero_trust_access_application.qbittorrent_nathanjn_com
}

resource "cloudflare_zero_trust_access_application" "tautulli_nathanjn_com" {
  zone_id                    = data.cloudflare_zone.nathanjn_com.id
  name                       = "tautulli.nathanjn.com"
  domain                     = "tautulli.nathanjn.com"
  session_duration           = "2h"
  auto_redirect_to_identity  = true
  allowed_idps               = ["97ed69f2-279d-4cef-bc29-65b6f7e915bf"]
  type                       = "self_hosted"
  http_only_cookie_attribute = true

  policies = [
    {
      name       = "User auth"
      decision   = "allow"
      precedence = 1
      include = [
        {
          email = { email = "nathan.james.norris@gmail.com" }
        }
      ]
    }
  ]
}

moved {
  from = cloudflare_access_application.tautulli_nathanjn_com
  to   = cloudflare_zero_trust_access_application.tautulli_nathanjn_com
}

resource "cloudflare_zero_trust_access_application" "maintainerr_nathanjn_com" {
  zone_id                    = data.cloudflare_zone.nathanjn_com.id
  name                       = "maintainerr.nathanjn.com"
  domain                     = "maintainerr.nathanjn.com"
  session_duration           = "2h"
  auto_redirect_to_identity  = true
  allowed_idps               = ["97ed69f2-279d-4cef-bc29-65b6f7e915bf"]
  type                       = "self_hosted"
  http_only_cookie_attribute = true

  policies = [
    {
      name       = "User auth"
      decision   = "allow"
      precedence = 1
      include = [
        {
          email = { email = "nathan.james.norris@gmail.com" }
        }
      ]
    }
  ]
}

moved {
  from = cloudflare_access_application.maintainerr_nathanjn_com
  to   = cloudflare_zero_trust_access_application.maintainerr_nathanjn_com
}

resource "cloudflare_zero_trust_access_application" "kopia_nathanjn_com" {
  zone_id                    = data.cloudflare_zone.nathanjn_com.id
  name                       = "kopia.nathanjn.com"
  domain                     = "kopia.nathanjn.com"
  session_duration           = "2h"
  auto_redirect_to_identity  = true
  allowed_idps               = ["97ed69f2-279d-4cef-bc29-65b6f7e915bf"]
  type                       = "self_hosted"
  http_only_cookie_attribute = true

  policies = [
    {
      name       = "User auth"
      decision   = "allow"
      precedence = 1
      include = [
        {
          email = { email = "nathan.james.norris@gmail.com" }
        }
      ]
    }
  ]
}

moved {
  from = cloudflare_access_application.kopia_nathanjn_com
  to   = cloudflare_zero_trust_access_application.kopia_nathanjn_com
}

resource "cloudflare_zero_trust_access_application" "matter_nathanjn_com" {
  zone_id                    = data.cloudflare_zone.nathanjn_com.id
  name                       = "matter.nathanjn.com"
  domain                     = "matter.nathanjn.com"
  session_duration           = "2h"
  auto_redirect_to_identity  = true
  allowed_idps               = ["97ed69f2-279d-4cef-bc29-65b6f7e915bf"]
  type                       = "self_hosted"
  http_only_cookie_attribute = true

  policies = [
    {
      name       = "User auth"
      decision   = "allow"
      precedence = 1
      include = [
        {
          email = { email = "nathan.james.norris@gmail.com" }
        }
      ]
    }
  ]
}

moved {
  from = cloudflare_access_application.matter_nathanjn_com
  to   = cloudflare_zero_trust_access_application.matter_nathanjn_com
}
