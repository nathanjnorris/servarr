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
| Kopia runs `--disable-csrf-token-checks` (accepted) | Kopia has no CSRF setting in its UI; its web credentials are already passed as env (#213), not arguments. | Accepted because Kopia is only reachable through Cloudflare Access plus basic auth. Revisit if Kopia adds a CSRF option. |
| `optimised-cleanup.service` runs as root straight from the `nathan`-owned checkout (`/home/nathan/servarr/scripts/optimised-cleanup.py`) | Same pattern as the data-mount-guard finding fixed in #215, noticed afterwards. Anyone who can write the checkout as `nathan` could run code as root at 02:20. | Install a root-owned copy in `setup.sh` (as done for `/usr/local/sbin/data-mount-guard`, fatal on failure) or run the unit as `User=nathan` with docker group access. |
| Sonarr, Radarr and Prowlarr use `External` authentication (accepted) | They share gluetun's network with no published ports and are reached only through Cloudflare Access, so the remaining exposure is another container on `servarr_default` reaching them. | Revisit if an untrusted container is ever added to that network; then switch to Forms authentication. |

See also `HOST.md` (host and app-DB settings), `NON_TERRAFORM_CONFIG.md` (settings with no Terraform resource) and `SECRETS.md` (credential inventory and rotation).
