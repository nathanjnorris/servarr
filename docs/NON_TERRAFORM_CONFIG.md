# Configuration Terraform cannot manage

Rule: configure things with Terraform whenever a provider resource exists. Look it up first with the Terraform MCP
server (`get_provider_capabilities`, `search_providers`) and record the answer below. Only when there is no resource
do we fall back to an API/CLI call, and then it must be an **idempotent script run by the deploy workflow** with a
repo secret, listed here. No one-off live changes.

| Setting | Why not Terraform | Where it is enforced | Secret | Checked |
| --- | --- | --- | --- | --- |
| GitHub AI Scan (`pr_scan`, `repository_scan`) on this repo | no resource or attribute in `integrations/github` 6.13.0 (latest, checked via Terraform MCP) | `scripts/github-settings.sh`, run by the `github_settings` job in `.github/workflows/deploy.yml` | `GHA_SERVARR_CODE_SCAN` | 2026-11-21 |
| Fork PR contributor approval policy (`first_time_contributors`, approved by the owner 2026-11-21) | `github_actions_repository_permissions` (6.13.0) has no attribute for it (checked via Terraform MCP) | `scripts/github-settings.sh` | `GHA_SERVARR_CODE_SCAN` | 2026-11-21 |
| Cloudflare account token `servarr-readonly-agents` (read-only: Access apps and policies, Access service tokens, Cloudflare Tunnel at account level; Access apps, DNS, Zone, Zone Settings, Zone WAF on `nathanjn.com`; expires 2027-11-25) | owner decision 2026-11-25 to create it with the `cf` CLI. A Terraform-managed token would need the provider token to hold API Tokens: Edit and would put the token value in state | created once with `cf accounts tokens create`; rotation steps in `SECRETS.md` | `CLOUDFLARE_API_TOKEN_READONLY` | 2026-11-25 |

## Terraform Cloud workspace `servarr` (managed through the Terraform MCP)

No HCL manages TFC itself (the `hashicorp/tfe` provider is not used). The owner decided on 2026-11-22 that agents
change this workspace through the Terraform MCP (rules in `CLAUDE.md`, "Terraform Cloud workspace"). Record every
change here.

| Setting | Value | Changed |
| --- | --- | --- |
| Organization / workspace | `nathanjnorris-org` / `servarr` (`ws-XG6CTSfjg3x13dv6`), free plan (only the `owners` team) | - |
| Terraform version | 1.17.2 (matches `validate.yml` and `providers.tf`) | 2026-11-21 |
| Execution / apply | remote execution, auto-apply (applies come from the Deploy workflow's `terraform_apply` job and merges) | - |
| Variables | Terraform variables for every input in `variables.tf` (see README "Inputs"). Secrets are `sensitive`, and their rotation is tracked in `SECRETS.md`. | - |

Not enforceable by script (UI or no API), noted so they are not forgotten:

| Item | What | Notes |
| --- | --- | --- |
| Mend Renovate dashboard (`developer.mend.io`): Silent mode must be OFF, Dependency Updates ON | web-only settings of the hosted Renovate app, no API or Terraform resource | Silent mode produces no PRs, branches or Dependency Dashboard issue at all. Found on 2026-11-21 as the reason Renovate was inert. The in-repo `"mode": "full"` in `renovate.json` is set as well. |
| AI Scan, repository scan | must be started by hand from the repo's code scanning alerts page | no schedule, no API; run it after large changes |
| Scan for AI applications | organisation-level setting | not available on a personal-account repo |
| Copilot cloud agent firewall custom allowlist (repo Settings, Copilot, Cloud agent) | web-only | `registry.terraform.io`, `registry-1.docker.io`, `auth.docker.io`, `production.cloudflare.docker.com` (Terraform MCP image), `api.cloudflare.com`, `registry.npmjs.org` |
| Copilot cloud agent MCP configuration (same page) | web-only | `{"mcpServers":{"renovate":{"type":"local","command":"renovate-mcp","args":[],"env":{"RENOVATE_PLATFORM":"local"},"tools":["validate_config","lint_config","explain_config","explain_dependency","test_package_rules","preview_custom_manager","resolve_config","dry_run","dry_run_diff","annotate_dry_run"]}}}`. No token in its env, so `dry_run` can only run locally. |

When a newer provider version adds a resource for one of these, move it into Terraform and delete its row.

Cloudflare dashboard-only items (HA client certificate and hostname association, zone SSL mode) and settings that live in
application databases on the host (qBittorrent whitelist, arr auth, Pushbullet, Plex optimise jobs, Kuma monitors) are
listed in `HOST.md`.
