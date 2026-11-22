# Tracked technical debt

Things we know are unfinished, with why and the safe way to finish them. Delete a row when it is done.

## Terraform and providers

| Item | Why it is not done | Safe way to finish it |
| --- | --- | --- |
| Tunnel `config_src` is `local` in state (live API reports `cloudflare`) although the tunnel is configured remotely (`remote_config = true`) | Setting it to `cloudflare` makes Terraform delete and recreate the tunnel (new tunnel ID and token), so it was left unset. A future update of the tunnel resource could send the default. | Only change it as a deliberate, tested tunnel replacement (new token to the host and GitHub secret, DNS re-pointed), or find a provider version that updates it in place. |

## CI and repository

| Item | Why it is not done | Safe way to finish it |
| --- | --- | --- |
| AI Scan "repository" scan does not run by itself | GitHub has no schedule or API for it. | Start it from the repo's code scanning alerts page after large changes. |
| Both GitHub PATs have no expiry | Chosen for low maintenance. | Review yearly (dates in `SECRETS.md`). |
| Kopia runs `--disable-csrf-token-checks` (accepted) | Kopia has no CSRF setting in its UI; its web credentials are already passed as env (#213), not arguments. | Accepted because Kopia is only reachable through Cloudflare Access plus basic auth. Revisit if Kopia adds a CSRF option. |
| Gluetun's control server (`gluetun:8000`) answers without authentication (found 2026-11-22: `GET /v1/vpn/status` and `/v1/publicip/ip` return 200 from any container on `servarr_default`) | Out of scope for the Kuma/Access cleanup; Kuma's Gluetun monitor uses `/v1/vpn/status`. Newer gluetun versions support role-based auth for the control server. | Configure gluetun's control-server auth (`HTTP_CONTROL_SERVER_AUTH_CONFIG_FILEPATH`): allow only `GET /v1/vpn/status` without auth (for Kuma) and require a key for everything else, especially the `PUT` routes that change the VPN. Verify which routes are open in the pinned version first. |
| Sonarr, Radarr and Prowlarr use `External` authentication (accepted) | They share gluetun's network with no published ports and are reached only through Cloudflare Access, so the remaining exposure is another container on `servarr_default` reaching them. | Revisit if an untrusted container is ever added to that network; then switch to Forms authentication. |

See also `HOST.md` (host and app-DB settings), `NON_TERRAFORM_CONFIG.md` (settings with no Terraform resource) and `SECRETS.md` (credential inventory and rotation).
