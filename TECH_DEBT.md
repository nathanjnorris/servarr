# Tracked technical debt

Things we know are unfinished, with why and the safe way to finish them. Delete a row when it is done.

## Terraform and providers

| Item | Why it is not done | Safe way to finish it |
| --- | --- | --- |
| Cloudflare Access applications still rely on their live application-scoped policies (`lifecycle { ignore_changes = [policies] }` on each `cloudflare_zero_trust_access_application`) | The v5 provider moved the policies inline on the application. The old policy resources were removed from state without destroying anything; converting them needs a plan read per application. | Convert one application at a time to inline `policies`, starting with a low-risk one (kopia, maintainerr). Read each plan: the application must update in place and nothing may be recreated. Confirm sign-in still works, then remove `ignore_changes` for that application. |
| Access session cookies are not HttpOnly (`http_only_cookie_attribute = false` on all 12 Access applications, as they already were live) | Preserved as-is by the v5 migration; turning it on changes behaviour for anything that reads the cookie. | Enable it one application at a time with a plan read, starting with a low-risk app, and confirm sign-in still works. |
| Tunnel `config_src` is `local` in state although the tunnel is configured remotely (`remote_config = true`) | Setting it to `cloudflare` makes Terraform delete and recreate the tunnel (new tunnel ID and token), so it was left unset. A future update of the tunnel resource could send the default. | Only change it as a deliberate, tested tunnel replacement (new token to the host and GitHub secret, DNS re-pointed), or find a provider version that updates it in place. |

## CI and repository

| Item | Why it is not done | Safe way to finish it |
| --- | --- | --- |
| AI Scan "repository" scan does not run by itself | GitHub has no schedule or API for it. | Start it from the repo's code scanning alerts page after large changes. |
| Both GitHub PATs have no expiry | Chosen for low maintenance. | Review yearly (dates in `SECRETS.md`). |

See also `NON_TERRAFORM_CONFIG.md` (settings with no Terraform resource) and `SECRETS.md` (credential inventory and rotation).
