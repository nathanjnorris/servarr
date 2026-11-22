# Configuration Terraform cannot manage

Rule: configure things with Terraform whenever a provider resource exists. Look it up first with the Terraform MCP
server (`get_provider_capabilities`, `search_providers`) and record the answer below. Only when there is no resource
do we fall back to an API/CLI call, and then it must be an **idempotent script run by the deploy workflow** with a
repo secret, listed here. No one-off live changes.

| Setting | Why not Terraform | Where it is enforced | Secret | Checked |
| --- | --- | --- | --- | --- |
| GitHub AI Scan (`pr_scan`, `repository_scan`) on this repo | no resource or attribute in `integrations/github` 6.13.0 (latest, checked via Terraform MCP) | `scripts/github-settings.sh`, run by the `github_settings` job in `.github/workflows/deploy.yml` | `GHA_SERVARR_CODE_SCAN` | 2026-11-21 |
| Fork PR contributor approval policy (`first_time_contributors`, approved by the owner 2026-11-21) | `github_actions_repository_permissions` (6.13.0) has no attribute for it (checked via Terraform MCP) | `scripts/github-settings.sh` | `GHA_SERVARR_CODE_SCAN` | 2026-11-21 |

Not enforceable by script (UI or no API), noted so they are not forgotten:

| Item | What | Notes |
| --- | --- | --- |
| Mend Renovate dashboard (`developer.mend.io`): Silent mode must be OFF, Dependency Updates ON | web-only settings of the hosted Renovate app, no API or Terraform resource | Silent mode produces no PRs, branches or Dependency Dashboard issue at all. Found on 2026-11-21 as the reason Renovate was inert. The in-repo `"mode": "full"` in `renovate.json` is set as well. |
| AI Scan, repository scan | must be started by hand from the repo's code scanning alerts page | no schedule, no API; run it after large changes |
| Scan for AI applications | organisation-level setting | not available on a personal-account repo |

When a newer provider version adds a resource for one of these, move it into Terraform and delete its row.

Cloudflare dashboard-only items (HA client certificate and hostname association, zone SSL mode) and settings that live in
application databases on the host (qBittorrent whitelist, arr auth, Pushbullet, Plex optimise jobs, Kuma monitors) are
listed in `HOST.md`.
