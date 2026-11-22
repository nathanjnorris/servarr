# Tracked technical debt

Things we know are unfinished, with why and the safe way to finish them. Delete a row when it is done.

## Terraform and providers

| Item | Why it is not done | Safe way to finish it |
| --- | --- | --- |
| Access session cookies are not HttpOnly (`http_only_cookie_attribute = false` on all 12 Access applications, as they already were live) | Preserved as-is by the v5 migration; turning it on changes behaviour for anything that reads the cookie. | Enable it one application at a time with a plan read, starting with a low-risk app, and confirm sign-in still works. |
| Tunnel `config_src` is `local` in state (live API reports `cloudflare`) although the tunnel is configured remotely (`remote_config = true`) | Setting it to `cloudflare` makes Terraform delete and recreate the tunnel (new tunnel ID and token), so it was left unset. A future update of the tunnel resource could send the default. | Only change it as a deliberate, tested tunnel replacement (new token to the host and GitHub secret, DNS re-pointed), or find a provider version that updates it in place. |

## CI and repository

| Item | Why it is not done | Safe way to finish it |
| --- | --- | --- |
| AI Scan "repository" scan does not run by itself | GitHub has no schedule or API for it. | Start it from the repo's code scanning alerts page after large changes. |
| Both GitHub PATs have no expiry | Chosen for low maintenance. | Review yearly (dates in `SECRETS.md`). |
| AI scan: `data-mount-guard.service` runs as root from the user-owned checkout (`setup.sh`) | The unit executes `scripts/data-mount-guard.sh` from `/home/nathan/servarr`, so anyone who can write as that user gets root within a minute. Fixing it changes a live host unit. | Install the script root-owned (for example under `/usr/local/sbin`, copied by `setup.sh`) and point the unit at that copy; apply and verify on a quiet host. |
| AI scan: Kopia runs with `--disable-csrf-token-checks` (`docker-compose.yml`) | Kopia sits behind Cloudflare Access, and the flag was set so the UI works through the tunnel. | Test the UI with the checks enabled and remove the flag if it works. |
| AI scan: Sonarr, Radarr and Prowlarr use `External` authentication | Cloudflare Access is the only login, so any container on the shared network can reach the origins directly. | Move each to Forms authentication with the API key, or isolate the network so only cloudflared reaches them. Do not edit the arr settings without a backup. |
| AI scan: Uptime Kuma mounts the Docker socket and is exposed through the tunnel | Kuma uses the socket for container monitors. A compromise of it would give control of the host. | Put a read-only Docker socket proxy in front, or drop the Docker monitors and the mount. |

See also `NON_TERRAFORM_CONFIG.md` (settings with no Terraform resource) and `SECRETS.md` (credential inventory and rotation).
