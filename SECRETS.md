# Secrets inventory and rotation

No secret values live in this repo, and this file deliberately holds no identifiers beyond the secret names (which are already visible in the workflows), because the repository is public. This file records **where each secret is stored, who uses it, when it
must be rotated, and how**. A weekly workflow (`.github/workflows/secrets-expiry.yml`) reads the table below
and opens an issue assigned to the owner when a row's **Review by** date is within 30 days.

**Keeping this honest:** whenever you rotate or add a secret, update its row (including the date) in the
same PR. `scripts/secrets-expiry-check.sh` is what parses the table, so keep the last column a plain
`YYYY-MM-DD`.

## Where secrets live

| Store | What goes there | How to set |
| --- | --- | --- |
| GitHub Actions secrets | values the workflows need (deploy, plan) | `gh secret set NAME` (reads stdin, never put the value on the command line) |
| GitHub Dependabot secrets | the same TFC token, because Dependabot PRs cannot read Actions secrets | `gh secret set TF_API_TOKEN --app dependabot` |
| Terraform Cloud workspace variables (`servarr`) | values Terraform itself needs (providers, `.env` contents) | TFC API `PATCH /api/v2/workspaces/<workspace-id>/vars/<var-id>` with `sensitive: true` |
| Host `.env` | written by the deploy workflow from the secrets above, mode 0600, never committed | nothing to do, re-written every deploy |

## Inventory

`Review by` is the expiry date when the secret expires, otherwise the date by which it should be rotated or
re-confirmed. Names are the exact secret or variable names.

| Name | Store | Used by | Rotate how | Review by |
| --- | --- | --- | --- | --- |
| `TF_API_TOKEN` (Dependabot) | GitHub Dependabot | Dependabot/Renovate PR plans | TFC team token (a team has one token: regenerating it revokes the old one, so set both copies in the same step). Expires after 1 year. | 2027-11-20 |
| `TF_API_TOKEN` (Actions) | GitHub Actions | `tfci` plan and apply in CI | a long-lived TFC token; replace it with the team token above | 2027-03-23 |
| `github_access_token` | TFC variable | Terraform GitHub provider (repo, ruleset, secrets) | fine-grained PAT, repo `servarr` only, Administration **write**, Secrets **write**, Metadata read, 1 year; paste into the TFC variable | unknown, confirm and update |
| `cloudflare_api_token` | TFC variable | Terraform Cloudflare provider | Cloudflare dashboard, My Profile, API Tokens; paste into the TFC variable | unknown, confirm and update |
| `GOOGLE_CREDENTIALS` | TFC env variable | Terraform Google provider | rotate the service account key in GCP IAM, paste the JSON into the variable | 2027-03-23 |
| `tailscale_client_id`, `tailscale_client_secret`, `tailscale_client_secret_exit_node` | TFC variables | Terraform Tailscale provider | Tailscale admin console, Settings, OAuth clients; regenerate the secret | 2027-09-28 |
| `TS_OAUTH_CLIENT_ID`, `TS_OAUTH_SECRET` | GitHub Actions | workflows join the tailnet as `tag:gha` to reach the host | Tailscale OAuth client; regenerate, then `gh secret set` both | 2027-09-28 |
| `TS_CLIENT_SECRET_EXIT_NODE` | GitHub Actions | exit node auth key on the host | Tailscale admin console; regenerate | 2027-10-21 |
| `SSH_PRIVATE_KEY_VALUE` | GitHub Actions and TFC (`ssh_private_key_value`) | deploy and Terraform SSH to the host | new ed25519 key, add the public half to `~/.ssh/authorized_keys` on the host, set both stores, then remove the old public key | 2027-03-21 |
| `SUDO_PASSWORD` | GitHub Actions and TFC (`sudo_password`) | Terraform host provisioning | change the account password on the host, set both stores | 2027-03-26 |
| `SERVARR_TUNNEL_TOKEN` | GitHub Actions | cloudflared on the host | Cloudflare Zero Trust, Tunnels, `servarr`, refresh token; `gh secret set` | 2027-03-20 |
| `HOME_ASSISTANT_DNS_TOKEN` | GitHub Actions | Home Assistant DNS challenge | provider dashboard; `gh secret set` | 2027-11-15 |
| `GLUETUN_PRIVATE_KEY`, `GLUETUN_PRESHARED_KEY`, `GLUETUN_WIREGUARD_ADDRESS`, `GLUETUN_PORT` | GitHub Actions and TFC (`gluetun_*`) | VPN for qBittorrent | generate a new WireGuard config at the VPN provider, set all four in both stores | 2027-10-18 |
| `KOPIA_PASSWORD` | GitHub Actions and TFC (`kopia_password`) | backup repository password | **do not rotate casually**: changing it needs `kopia repository change-password`, otherwise backups become unreadable | 2027-04-01 |

## App-level credentials (not in GitHub)

Pushbullet, arr API keys, Plex and Maintainerr settings live only in each app's own config on the host and
are included in the host config backups. Rotate them in the app, then update the dependants listed in
`MANUAL_CONFIG.md`.

## Rotating, step by step

1. Create the new credential with the narrowest scope that works.
2. Set it in every store listed in its row (some secrets exist in two stores).
3. Run `gh workflow run deploy.yml -f force=true` or wait for the next deploy and confirm it is green.
4. Revoke the old credential.
5. Update the row's **Review by** date in this file and merge.
