---
name: servarr-cloudflare
description: Work on servarr's Cloudflare setup (provider v5 Terraform in cloudflare.tf - DNS, tunnel, 12 Zero Trust Access apps with user-only inline policies, service tokens, zone settings, WAF/mTLS) and verify live state read-only with the `cf` CLI. Use for any Cloudflare change, Access/tunnel troubleshooting, or post-apply verification.
---

# Cloudflare for servarr

Terraform (`cloudflare.tf`, provider `cloudflare/cloudflare ~> 5.29`) is the source of truth. The `cf` CLI is for
**read-only** verification and diagnosis. Never use it to write configuration.

## `cf` CLI

- Discover commands with `cf cli search "<generic task>"`. Keep queries anonymous: no domain, account ID, names or
  tokens. Then run `<command> --help`. Do not crawl nested `--help`.
- Check login with `cf auth whoami`. If it fails, ask the user to run `! cf auth login`. Never print tokens.
- Commands known to work:

```bash
cf zero-trust access applications list --zone nathanjn.com   # prints a result_info: line, then a JSON array
cf tunnels list
cf docs search "<question>"                                  # Cloudflare docs
```

Verification pattern for any Access/tunnel change:
1. Before applying, snapshot the live JSON to `$TMPDIR`.
2. After the deploy applies, snapshot again and diff.
3. Application IDs and AUD tags must be unchanged, the policy count must match the plan, and the tunnel ID must be
   unchanged.

## What exists

| Thing | Notes |
| --- | --- |
| 12 Access applications (`cloudflare_zero_trust_access_application`) | Inline `policies` only (no reusable policies, no groups). Every app has a single "User auth" policy (`allow`, precedence 1, owner email). No service token is accepted: Uptime Kuma checks the apps directly on the Docker network (for example `http://gluetun:8989/ping`), not through Cloudflare. `http_only_cookie_attribute = true` on all 12 apps (AI Scan #10). |
| Not behind Access | Plex, Seerr, Wizarr and Uptime Kuma (native auth; Kuma's status page is public by design). Home Assistant (`ha.`) uses an mTLS WAF rule (`require_ha_client_certificate`) with a dashboard-managed client certificate. |
| Tunnel `servarr_tunnel` | `cloudflare_zero_trust_tunnel_cloudflared` plus `_config`; the token comes from data source `cloudflare_zero_trust_tunnel_cloudflared_token` and is pushed to the `SERVARR_TUNNEL_TOKEN` GitHub Actions secret by Terraform (`github.tf`). |
| Service tokens | `github_actions`, `google_assistant`. The `uptime_kuma` token was removed on 2026-11-22 (AI Scan #13); do not reintroduce a token that bypasses Access for monitoring. |
| Zone settings | one `cloudflare_zone_setting` per setting (8; `http3 = off` because of mTLS) |
| Outside Terraform | the HA client certificate and its hostname association, zone SSL mode `flexible`, unrelated mail/Pages records (see `docs/NON_TERRAFORM_CONFIG.md`) |

## v5 gotchas (learned the hard way)

- **Never set `config_src` on the tunnel.** State says `local`, the API says `cloudflare`, and setting it forces a
  **replacement**: a new tunnel ID and token, which takes everything down. This is tracked in `docs/TECH_DEBT.md`.
- Keep `http_host_header = ""` explicit in the tunnel config, and `is_robots_txt_managed = true` on bot management.
  Leaving these to defaults produces perpetual drift.
- Removing a policy from an application makes Cloudflare garbage-collect it. Plan carefully, one app per PR when
  risky.
- Resource names: `cloudflare_record` is now `cloudflare_dns_record`; zone settings moved from `zone_settings_override`
  to one `cloudflare_zone_setting` each (imported); Access policies are inline, not `cloudflare_access_policy`.
- Look up resource schemas with the Terraform MCP (`get_provider_details`, provider `cloudflare/cloudflare`) before
  writing HCL. v5 attribute shapes differ from v4 examples on the web.
- Every resource-changing PR: regenerate the README (terraform-docs) and read the plan with
  `servarr-ship/scripts/plan-diff.sh`. Zero `replace_paths` on Access apps or the tunnel is the bar.

## Credentials

The Terraform API token is `cloudflare_api_token`, a TFC workspace variable. It has no expiry and is reviewed yearly
(see `docs/SECRETS.md`). The `cf` CLI uses the user's own login profile, not that token.
