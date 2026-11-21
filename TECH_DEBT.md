# Tracked technical debt

Things we know are unfinished, with why and the safe way to finish them. Delete a row when it is done.

## Terraform and providers

| Item | Why it is not done | Safe way to finish it |
| --- | --- | --- |
| Cloudflare Access applications still rely on their live application-scoped policies (`lifecycle { ignore_changes = [policies] }` on each `cloudflare_zero_trust_access_application`) | The v5 provider moved the policies inline on the application. The old policy resources were removed from state without destroying anything; converting them needs a plan read per application. | Convert one application at a time to inline `policies`, starting with a low-risk one (kopia, maintainerr). Read each plan: the application must update in place and nothing may be recreated. Confirm sign-in still works, then remove `ignore_changes` for that application. |

## CI and repository

| Item | Why it is not done | Safe way to finish it |
| --- | --- | --- |
| AI Scan "repository" scan does not run by itself | GitHub has no schedule or API for it. | Start it from the repo's code scanning alerts page after large changes. |
| Both GitHub PATs have no expiry | Chosen for low maintenance. | Review yearly (dates in `SECRETS.md`). |

See also `NON_TERRAFORM_CONFIG.md` (settings with no Terraform resource) and `SECRETS.md` (credential inventory and rotation).
