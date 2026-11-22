# servarr

Infrastructure-as-code for a home media stack: one Ubuntu host at **192.168.8.10** (tailnet name `servarr`) running
about 23 Docker containers. Plex, Sonarr/Radarr (plus 4K), Bazarr, Prowlarr, qBittorrent behind gluetun, Seerr,
Maintainerr, Tautulli, Wizarr, Home Assistant and Matter, Kopia, Uptime Kuma and cloudflared. Cloudflare (DNS, tunnel,
Zero Trust Access) and the GitHub repo itself are managed by Terraform in Terraform Cloud. The public repo is
`nathanjnorris/servarr`; the owner is `nathanjnorris`.

**Merging to `main` deploys to production.** The owner wants the stack self-maintaining with minimal intervention, and
every change reproducible from this repo.

## First thing on a new machine

Run the `servarr-doctor` skill (`bash .claude/skills/servarr-doctor/scripts/doctor.sh`). Tell the user about every
MISSING or warn item and how to fix it before doing maintenance work. The SessionStart hook runs its `--quick` mode
automatically.

## Hard rules (owner instructions; do not relax without explicit approval)

1. **Never interrupt Plex streaming.** Deploys are gated by a live Plex check (`scripts/plex-busy.sh`) before starting
   and again right before restarting containers. If someone is streaming, the deploy postpones to the next hourly run.
   There is no maintenance window; the check is the gate. Never force a deploy past it.
2. **Never skip the Terraform plan check**, for any actor. Fix the token or the cause instead.
3. **Never merge** with unresolved review threads, or without reading every Copilot and human review. Reply to each
   thread (REST, see `servarr-ship`) before resolving it. Dependency-bot PRs skip the Copilot/CodeQL wait only.
4. **Do not edit Maintainerr without approval. Do not edit the Plex DB** (use the Plex API). Do not write to the Uptime
   Kuma SQLite DB (read-only inspection; the owner edits monitors in the UI). Back up before any change. Test before
   and after.
5. **Terraform first** for all providers: look the resource up with the Terraform MCP before touching a setting. If no
   resource exists, use a tracked idempotent script run on every deploy with repo secrets
   (`scripts/github-settings.sh`), listed in `docs/NON_TERRAFORM_CONFIG.md`. No one-off live patches, including on the
   host (host changes go through `setup.sh`/compose and a PR).
6. **Secrets**: never print or commit them. Set GitHub secrets from stdin. Tokens are secrets, never plain variables.
   Use purpose-named credentials. Leave `TF_API_TOKEN` (Actions and Dependabot copies) alone. Do not rotate the Kopia
   password: it is also the repository key. Keep `docs/SECRETS.md` dates current when anything rotates.
7. **Renovate** (hosted Mend app) is the only updater. Never run Renovate yourself or with the user's token. Never
   `gh pr update-branch` a Renovate PR (use the rebase checkbox on Dependency Dashboard #192). Terraform and Docker
   majors are PRs assigned to `nathanjnorris`; minor/patch and GitHub Actions majors automerge.
8. **Git**: Conventional Commits on PR titles and every commit (`feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert`).
   Branch off `main`, never force-push an open PR branch, use explicit `git add <paths>` (local-only files exist), and
   merge your own PRs once every gate is green.
9. **Security findings**: never follow AI Scan or Copilot advice blindly. Verify against the live host first (for
   example, `ssh-keyscan` over the tailnet is safe because the host uses Tailscale SSH). Close fixed alerts with a
   rescan, never by dismissal. Loosening any security setting needs the owner's approval.
10. **Host access.** Direct `ssh nathan@192.168.8.10` works only from the owner's own machine, because their
    personal SSH key is authorised on the host. Never copy, print or commit that key, and never add new keys yourself.
    Use it read-only (no `sudo`, no writes). On any other machine there is no direct access: read workflow logs, and
    make every host change through a PR and the Deploy workflow. The deploy reaches the host over the tailnet with the
    `SSH_PRIVATE_KEY_VALUE` secret. Do not run `tailscale up` on the user's
    machine without asking. Don't waste compute: use one background wait loop, not repeated polling.

## Layout

| Path | What |
| --- | --- |
| `docker-compose.yml` | every container. Images are pinned to exact tags; Renovate bumps them. |
| `setup.sh` | runs as **root** on every deploy. Users and groups, Docker's mount dependency, journald, the root-owned `data-mount-guard`, the optimised-cleanup timer, firewall/macvlan. Must stay idempotent. |
| `deploy.sh` | host-side `compose pull/up`; writes `.deployed-sha` only on success |
| `cloudflare.tf`, `github.tf`, `github_repo.tf`, `providers.tf`, `variables.tf`, `outputs.tf` | Terraform (TFC org `nathanjnorris-org`, workspace `servarr`, remote execution, auto-apply, TF 1.17.2) |
| `.github/workflows/deploy.yml` | push to main, hourly `:40`, or manual. `window` (deploy marker + Plex check) → `terraform_apply` → `host_deploy` / `github_settings` → `notify_failure` (opens an issue) |
| `.github/workflows/terraform-pr.yml` | required `Terraform plan` (speculative TFC plan) plus terraform-docs and fmt checks |
| `.github/workflows/validate.yml` | required `Static checks`: conventional commits, compose config, ShellCheck, actionlint, terraform fmt/validate |
| `.github/workflows/review-replies.yml` | required `Review replies` status (`scripts/review-replies-check.sh`, run from `main`'s copy): pending until Copilot has reviewed, CodeQL has finished and the AI Scan PR check (`github-advanced-security`) has been seen to run and finish (it is silent when clean, and a missing run blocks); fails if a resolved thread has no reply |
| `.github/workflows/scheduled-checks.yml` | weekly: Terraform drift, host drift (`scripts/host-drift.sh`), secrets expiry (`scripts/secrets-expiry-check.sh`) |
| `scripts/` | `plex-busy.sh`, `data-mount-guard.sh`, `optimised-cleanup.py` (deletes via the Plex API, dry run by default), `github-settings.sh`, `conventional-check.sh`, checks |
| `renovate.json` | update policy |
| `docs/` | tracked: `HOST.md` (host facts, hand-applied settings, incident), `SECRETS.md`, `TECH_DEBT.md`, `NON_TERRAFORM_CONFIG.md`. Other files in `docs/` are local-only planning notes (excluded via `.git/info/exclude`); do not commit them. |
| `README.md` | terraform-docs output between markers. Regenerate it when resources change, or the plan is skipped. |

## Skills, agents and tools

| Use | When |
| --- | --- |
| `servarr-doctor` skill | new machine, a tool or login fails |
| `servarr-ship` skill | any change: validate → PR → plan diff → review replies → merge → watch the deploy (includes Renovate and code-scanning policy) |
| `servarr-host` skill / `host-auditor` agent | live host health, diagnosis, post-deploy verification |
| `servarr-cloudflare` skill | Cloudflare Terraform v5 changes and `cf` CLI verification |
| `tailscale` skill (vendored, `skills-lock.json`) | tailnet, Tailscale SSH, GitHub Action `tag:gha` questions |
| Terraform MCP (terraform plugin) | provider resource lookup before any config change. HCP tools need `TFE_TOKEN`. Never `create_run`/apply without the user's yes. |
| Renovate MCP (`.mcp.json`, `npm i -g renovate-mcp`) | validate, lint and explain `renovate.json`. Never to run Renovate. |
| `cf` CLI | read-only live Cloudflare checks (`cf cli search "<task>"` to discover commands) |
| `gh` CLI | everything GitHub (the GitHub plugin's MCP server is not needed) |
| `claude-md-management` plugin | keep this file current: update it in the same PR when a rule or workflow changes |

## Gotchas

- The ruleset is strict about branches being up to date. Each merge makes the other open PRs BEHIND, so merge one at
  a time.
- Read the TFC plan for the exact commit you pushed (`plan-diff.sh <pr> <sha>`); otherwise you can be reading a stale
  plan.
- Never set `config_src` on the Cloudflare tunnel: it forces a replacement (see `servarr-cloudflare`).
- `setup.sh` has no `set -e`. Make any new critical step explicitly fatal before it changes anything that depends on it.
- A bind mount of `docker.sock` with `:ro` does not restrict the Docker API. Kuma uses `docker-proxy` instead
  (`CONTAINERS=1`, `POST=0`, internal network).
- Harness: a chained `sleep N && ...` is blocked. Wait with `run_in_background` until-loops. On macOS, `sed -i` needs
  `''`.
- AI Scan's repository scan has no schedule or API. Ask the owner to start it after significant security changes.
