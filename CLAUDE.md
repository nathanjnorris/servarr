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
MISSING or warn item and how to fix it before doing maintenance work. The session-start hooks (Claude Code and
GitHub Copilot) run its `--quick` mode automatically.

## Hard rules (owner instructions; do not relax without explicit approval)

1. **Never interrupt Plex streaming.** Deploys are gated by a live Plex check (`scripts/plex-busy.sh`) before starting
   and again right before restarting containers. If someone is streaming, the deploy postpones to the next hourly run.
   There is no maintenance window; the check is the gate. Never force a deploy past it.
2. **Never skip the Terraform plan check**, for any actor. Fix the token or the cause instead.
3. **Never merge** with unresolved review threads, or without reading every Copilot and human review. Reply to each
   thread (REST, see `servarr-ship`) before resolving it. Dependency-bot PRs skip only the Copilot, CodeQL and AI Scan waits.
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
7. **Renovate** (hosted Mend app) is the only updater. Never run Renovate against the repo or with anyone's token.
   renovate-mcp's `dry_run` in **local mode** (no token, no PRs) is allowed for diagnosis (owner, 2026-11-25); the
   PreToolUse guard `.claude/hooks/renovate-guard.sh` blocks remote runs (Claude Code directly, Copilot through
   `.github/hooks/permission-policy.py`). Never
   `gh pr update-branch` a Renovate PR (use the rebase checkbox on Dependency Dashboard #192). Terraform and Docker
   majors are PRs assigned to `nathanjnorris`; minor/patch and GitHub Actions majors automerge. The "servarr deploy failed [HH:mm DD/MM/YY]" issue (Brisbane time) only @-mentions the owner, with no
   assignee: the owner assigns it, possibly to another account. Drift and secrets-expiry issues still mention and assign.
8. **Git**: Conventional Commits on PR titles and every commit (`feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert`).
   Branch off `main`, never force-push an open PR branch, use explicit `git add <paths>` (local-only files exist), and
   merge your own PRs once every gate is green.
9. **Security findings**: never follow AI Scan or Copilot advice blindly. Verify against the live host first (for
   example, an early `ssh-keyscan` finding was dismissed as a Tailscale-SSH false positive, but the drift job showed
   that pinning works, so it was a real issue). Close fixed alerts with a
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
| Terraform MCP (terraform plugin) | provider resource lookup before any config change. With `TFE_TOKEN` it also reads TFC workspaces, runs and plan logs, and **manages the `servarr` workspace** (see "Terraform Cloud workspace" below). Org-wide and run-starting tools are denied in `.claude/settings.json` (Copilot enforces the same list through its hook). If a server upgrade adds a new write tool, decide which side it belongs on. |
| Renovate MCP (`.mcp.json`, `npm i -g renovate-mcp`) | validate, lint and explain `renovate.json`, and diagnose updates with a local `dry_run` (`dryRunMode: lookup`). Never a remote run (blocked by `renovate-guard.sh`). |
| `cf` CLI | read-only live Cloudflare checks (`cf cli search "<task>"` to discover commands) |
| `gh` CLI | everything GitHub (the GitHub plugin's MCP server is not needed) |
| `claude-md-management` plugin | keep this file current: update it in the same PR when a rule or workflow changes |

## GitHub Copilot parity

This file is the instruction file for **both** Claude Code and GitHub Copilot (VS Code chat, Copilot CLI and the
cloud agent all read `CLAUDE.md`; there is deliberately no `AGENTS.md` copy). Every rule above applies to Copilot
too. VS Code's Copilot harness and Copilot CLI share one runtime. Where each Claude piece lives for Copilot:

| Claude Code | GitHub Copilot |
| --- | --- |
| `.claude/skills/*`, `.agents/skills/*` | read as-is (also by the cloud agent) |
| `.claude/agents/host-auditor.md` | `.github/agents/host-auditor.agent.md`, a thin wrapper that loads the Claude file's body (single source) |
| pr-review-toolkit `silent-failure-hunter` agent | not available: upstream's frontmatter isn't valid YAML, so Copilot skips it, and upstream takes no outside PRs. A wrapper that loaded the plugin file was dropped (#232 review: unverified plugin text steering file reads). Use Copilot's `code-review` agent or the other pr-review-toolkit agents; it reappears by itself when upstream fixes the YAML |
| `.mcp.json` (Renovate, tailscale-docs) | read as-is locally (the folder must be trusted). Cloud agent: not read |
| plugins in `.claude/settings.json` | `.github/copilot/settings.json` enables the same plugins (minus `security-guidance`) from `.github/plugin/marketplace.json`, which pins them to upstream commits. Copilot can't read `anthropics/claude-plugins-official` itself: one Claude-only entry makes it reject the whole file. Renovate bumps the `sha`s in one grouped PR on the first of each month and automerges it (owner, 2026-11-25). |
| `security-guidance` plugin | not enabled (it needs Anthropic credentials). Use Copilot's built-in `security-review` agent; AI Scan and CodeQL still gate PRs |
| `permissions.allow` / `deny` | `.github/hooks/permission-policy.py` (PreToolUse) reads the **same** lists from `.claude/settings.json`: deny always wins, shell allows only apply to commands without shell operators. Edit the rules only in `.claude/settings.json` |
| `tfc-workspace-guard.sh` hook | the same script, called from the Copilot policy hook (Copilot names the tools `terraform-<tool>`) |
| SessionStart doctor hook | `.github/hooks/session-start.sh` (wraps the output as `additionalContext`) |

Cloud agent: `.github/workflows/copilot-setup-steps.yml` preinstalls terraform, actionlint and renovate-mcp
(shellcheck, gh, jq, docker are on the runner). It has no host SSH and no Terraform Cloud token (it reads plans from
the PR flow). Its network is firewalled, so it works like "any other machine" in rule 10. For Cloudflare it has the
read-only `CLOUDFLARE_API_TOKEN_READONLY` Agents secret (use the API with it; `cf` login isn't available). Its
firewall allowlist and its Renovate MCP config are web-only repo settings, listed in `docs/NON_TERRAFORM_CONFIG.md`.

## Terraform Cloud workspace

TFC itself is **not** managed by HCL in this repo (no `hashicorp/tfe` provider). By the owner's decision (2026-11-22),
the `servarr` workspace in org `nathanjnorris-org` (id `ws-XG6CTSfjg3x13dv6`) is managed through the Terraform MCP:

- **Allowed, on `servarr` only:** `update_workspace` (settings such as the Terraform version), workspace variables
  (create, update, delete), workspace tags, lock/unlock. The org also holds `agentic-platform` and `tfc-agent`;
  never touch them.
- **Enforced** by the PreToolUse hook `.claude/hooks/tfc-workspace-guard.sh` (Claude Code directly; Copilot through
  `.github/hooks/permission-policy.py`). It blocks any mutating Terraform MCP
  call unless the org is `nathanjnorris-org` and the workspace is `servarr` (name or `ws-XG6CTSfjg3x13dv6`). It also
  blocks renames and fails closed on unknown argument shapes. Keep the hook if you change these tools.
- **Denied in settings** (`.claude/settings.json`; the Copilot hook applies the same list):
  - `create_run`, `apply_run` and `action_run`. The workspace auto-applies, so a run would change Cloudflare and
    GitHub outside the PR and Plex-gated deploy path. Infrastructure changes stay PR → plan → merge → Deploy.
  - Creating or deleting workspaces, force-unlock, projects, teams, variable sets, policy sets and stacks.
  - `cancel_run` and `discard_run`: they only take a run id, so the hook can't check which workspace the run belongs
    to. The owner handles stuck runs in the TFC UI.
- **Before a write:** read the current value first and tell the user the exact change. Get a yes for anything that
  affects runs: the Terraform version, execution or apply mode, or variables.
- **Secret variables:**
  - Always `sensitive: true`, and the value goes in through the tool call only. Never print or commit it.
  - Update the row in `docs/SECRETS.md` (store, review date) in a PR.
  - Leave the TFC token variables alone unless the owner asks.
- **Record it.** Every change goes into the "Terraform Cloud workspace `servarr`" section of
  `docs/NON_TERRAFORM_CONFIG.md` in a PR, because no HCL tracks it. Changing the workspace Terraform version also means
  matching `validate.yml`, `providers.tf` and the `CLAUDE.md` layout table.
- **Check the result:** run a speculative plan on a PR, or read the next Deploy's `terraform_apply` job.

## Gotchas

- The ruleset is strict about branches being up to date. Each merge makes the other open PRs BEHIND, so merge one at
  a time.
- Read the TFC plan for the exact commit you pushed (`plan-diff.sh <pr> <sha>`); otherwise you can be reading a stale
  plan.
- Never set `config_src` on the Cloudflare tunnel: it forces a replacement (see `servarr-cloudflare`).
- `setup.sh` has no `set -e`. Make any new critical step explicitly fatal before it changes anything that depends on it.
- A bind mount of `docker.sock` with `:ro` does not restrict the Docker API, and even a read-only socket proxy exposes
  `GET /containers/<id>/json`, which includes every container's env, secrets included. That's why Kuma has no Docker
  access at all and uses direct health checks (`docs/HOST.md`).
- Harness: a chained `sleep N && ...` is blocked. Wait with background until-loops (Claude Code `run_in_background`,
  Copilot an `async` shell). On macOS, `sed -i` needs `''`.
- AI Scan's repository scan has no schedule or API. Ask the owner to start it after significant security changes.
