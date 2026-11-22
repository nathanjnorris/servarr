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
| Gluetun's control server (`gluetun:8000`) answers without authentication (found 2026-11-22: `GET /v1/vpn/status` and `/v1/publicip/ip` return 200 from any container on `servarr_default`) | Out of scope for the Kuma/Access cleanup; Kuma's Gluetun monitor uses `/v1/vpn/status`. Newer gluetun versions support role-based auth for the control server. | Configure gluetun's control-server auth (`HTTP_CONTROL_SERVER_AUTH_CONFIG_FILEPATH`): allow only `GET /v1/vpn/status` without auth (for Kuma) and require a key for everything else, especially the `PUT` routes that change the VPN. Verify which routes are open in the pinned version first. |

## Accepted risks (owner decisions)

Code-scanning findings the owner chose not to fix, so a future rescan or agent doesn't reopen the debate without new
information. Revisit a row when its "Revisit if" condition happens.

| Alert | Risk | Why accepted | Revisit if |
| --- | --- | --- | --- |
| AI Scan #6 | Sonarr, Radarr and Prowlarr use `External` authentication, so anything that reaches them is trusted | They share gluetun's network with no published ports and are only published through Cloudflare Access (email + MFA) | An untrusted container joins `servarr_default`; then switch to Forms authentication |
| AI Scan #7 | Kopia runs `--disable-csrf-token-checks` | Kopia has no CSRF option to restore; its UI is behind Cloudflare Access plus basic auth (credentials via env since #213) | Kopia adds a CSRF setting |
| AI Scan #14 | Matter server uses host networking and serves an unauthenticated API on port 5580 | Host networking is needed to reach Matter devices on the LAN, and only Home Assistant uses it. Its public route (`matter.nathanjn.com` tunnel ingress, DNS record and Access app) was removed on 2026-11-22, so it is LAN-only. | Anything on the LAN becomes untrusted; then firewall 5580 to the host itself |
| AI Scan #15 | The review gate accepts a Copilot review of an earlier commit, so later pushes aren't Copilot-reviewed (`review_on_push = false`) | Re-reviewing every push costs too many Copilot premium requests. Only the owner can merge, fork PRs can't pass the Terraform plan (no secrets), and CodeQL, the AI Scan PR review and the plan re-run on every push against the head commit. | Copilot review cost stops mattering; then set `review_on_push = true` and require a review of the head commit |
| AI Scan #16 | Kopia is served over plain HTTP inside the Docker network, and its basic-auth password is the repository password | Traffic between cloudflared and Kopia stays on the local Docker bridge; reading it needs a compromised container on that network | An untrusted container joins the network; then enable Kopia TLS (`--tls-generate-cert`) and point the tunnel at HTTPS |
| AI Scan #17 | qBittorrent's `AuthSubnetWhitelist=172.18.0.0/16` skips its login for every container on the compose network | Cloudflare Access is the gate from outside; inside, it relies on every container on `servarr_default` being trusted | An untrusted container joins the network; then narrow the whitelist to cloudflared's address, or drop it and use the login |

See also `HOST.md` (host and app-DB settings), `NON_TERRAFORM_CONFIG.md` (settings with no Terraform resource) and `SECRETS.md` (credential inventory and rotation).
