# Tracked technical debt

Things we know are unfinished, with why and the safe way to finish them. Delete a row when it is done.

## Terraform and providers

| Item | Why it is not done | Safe way to finish it |
| --- | --- | --- |
| Cloudflare deprecated resources: `cloudflare_access_application`, `cloudflare_access_policy`, `cloudflare_access_service_token`, `cloudflare_tunnel`, `cloudflare_tunnel_config` (replacements are `cloudflare_zero_trust_*`) | They produce the "Deprecated Resource" warnings. The replacements need an import. Service token client secrets and the tunnel token cannot be read back after an import, and outputs/secrets depend on them (Google Assistant, `SERVARR_TUNNEL_TOKEN`). | Part of the staged Cloudflare v5 migration. Never destroy or recreate the tunnel or the Access policies. Take a state backup and a Cloudflare snapshot first. Use `import` blocks plus `removed { lifecycle { destroy = false } }` blocks, and stop if any plan wants to recreate something. |
| Cloudflare provider v4 to v5 (the `cloudflare_record` resource becomes `cloudflare_dns_record`) | Major provider upgrade with schema changes. Renovate is told not to raise it alone. | Same staged migration as above. |
| `github_actions_repository_permissions.sha_pinning_required` | Would break CI until every action reference is a commit SHA. | Enable it in Terraform after Renovate's digest-pin PR has merged. |

## CI and repository

| Item | Why it is not done | Safe way to finish it |
| --- | --- | --- |
| Actions are pinned by tag, not by commit SHA | Renovate has `helpers:pinGitHubActionDigests` but has not yet opened its first PR. | Merge Renovate's pin PR; then enable `sha_pinning_required` (above). |
| `.github/dependabot.yml` still exists | Waiting for proof that Renovate works. | Delete it once Renovate has opened and merged a PR. |
| AI Scan "repository" scan does not run by itself | GitHub has no schedule or API for it. | Start it from the repo's code scanning alerts page after large changes. |
| `cloudflare_api_token` expiry is unknown | Value is only readable inside Terraform Cloud. | Check it in the Cloudflare dashboard and set the date in `SECRETS.md`. |
| Both GitHub PATs have no expiry | Chosen for low maintenance. | Review yearly (dates in `SECRETS.md`). |

See also `NON_TERRAFORM_CONFIG.md` (settings with no Terraform resource) and `SECRETS.md` (credential inventory and rotation).
