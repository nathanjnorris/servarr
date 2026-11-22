---
name: servarr-ship
description: End-to-end procedure for changing servarr (Terraform, docker-compose, setup.sh, workflows, scripts) - branch, validate, open a conventional-commit PR, read the Terraform Cloud plan, answer Copilot/human review threads via REST, merge only when every gate is green, then watch the Plex-gated deploy. Use for any code or config change, Renovate PR triage, or "merge this PR".
---

# Ship a change to servarr

Merging to `main` deploys to the live host (Terraform apply + `setup.sh` + `docker compose up`). Treat every merge as a
production change. Helpers live in `.claude/skills/servarr-ship/scripts/`.

## 1. Before editing

- **Terraform first.** For any setting (GitHub, Cloudflare, Tailscale, anything), look up a provider resource with the
  Terraform MCP (`get_provider_capabilities`, `search_providers`, `get_provider_details`). If one exists, use it. If not,
  add an idempotent step to `scripts/github-settings.sh` (or another script the deploy runs every time) using a repo
  secret, and add a row to `docs/NON_TERRAFORM_CONFIG.md`. Never make one-off live changes. Say in the PR what the
  lookup found.
- Back up before changing anything stateful (state, app DBs, configs).
- Branch from fresh `main`: `git switch main && git pull && git switch -c <type>/<topic>`.

## 2. Validate locally (same checks as CI)

```bash
terraform fmt -check -recursive
terraform init -backend=false -input=false >/dev/null && terraform validate
docker compose config -q              # "variable is not set" warnings are expected without the host .env
shellcheck setup.sh deploy.sh macvlan.sh scripts/*.sh
actionlint
bash scripts/conventional-check.sh --self-test
```

If any `.tf` file changes resources, regenerate the README with the same terraform-docs image CI uses. Otherwise CI
fails the docs check and **skips the plan**.

```bash
docker run --rm -v "$PWD":/w -w /w \
  quay.io/terraform-docs/terraform-docs:0.25.1@sha256:7b2a74a2b9a9e6af41200335da47b73a64c39a0edd5afb91bc921f0a77eae681 \
  markdown table --indent 2 --output-mode inject --output-file README.md .
```

## 3. Commit and open the PR

- Conventional Commits on the PR title **and** every commit: `feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert`,
  optional `(scope)`, optional `!`. Enforced by `scripts/conventional-check.sh` in Static checks.
- `git add <explicit paths>`; never `git add -A` (local-only docs and tool dirs sit in the tree).
- End commits with the Co-Authored-By trailer the harness gives you. End PR bodies with the Claude Code line.
- Never force-push an open PR branch. Merge `main` in instead (`gh pr update-branch <n>` is fine on your own PRs).
- Terraform or Docker **major** upgrades: assign the PR to `nathanjnorris` and tell the user.

## 4. Gates (ruleset 8276307 on `main`, no bypass actors)

Required: `Terraform plan`, `Static checks`, `Review replies` status (waits for the Copilot review, CodeQL and the AI
Scan PR review check `github-advanced-security`, whose findings arrive as review threads), CodeQL, Copilot review, all threads resolved,
branch up to date (strict). Each merge puts the other open PRs BEHIND.

1. **Read the plan.** `bash .claude/skills/servarr-ship/scripts/plan-diff.sh <pr> <pushed-sha>`. Check every change:
   no unexpected `delete`/`create+delete`, no `replace_paths` on the tunnel or Access apps (their IDs and AUDs must not
   change). Never skip or bypass the plan check for any actor. If the TFC token is rejected, ask the user to
   `terraform login`.
2. **Read every review**, including `github-advanced-security` (AI Scan) threads, which need a reply like any other.
   `bash .claude/skills/servarr-ship/scripts/threads.sh <pr>`. Copilot findings are often
   right. Verify each one against the code or the live system, then fix it or explain why not. Do not agree just to
   be agreeable.
3. **Answer every thread, then resolve it:** write a JSON object mapping each unresolved thread's `id=` (from
   `threads.sh`) to its reply, and run `python3 .claude/skills/servarr-ship/scripts/reply-threads.py <pr> replies.json`. It uses REST and confirms
   there are 0 PENDING reviews. Resolving without replying fails the `Review replies` gate.
4. Merge when `mergeStateStatus` is `CLEAN`: `gh pr merge <n> --squash --subject "<conventional title> (#<n>)" --body ""`.

Dependency bots (Renovate) are exempt from the Copilot, CodeQL and AI Scan waits (AI Scan does not run on their PRs) but still need a green plan and Static checks.

## 5. Watch the deploy

`Deploy` runs on push to `main`, every hour at :40, and on manual dispatch (`gh workflow run deploy.yml`). Jobs:
- `window`: compares the host's `servarr/.deployed-sha` with `main` and runs a live Plex check (`scripts/plex-busy.sh`:
  0 idle, 10 streaming, 11 could not ask).
- Then `terraform_apply`, then `host_deploy` (SSH over Tailscale, `sudo -S bash setup.sh`, Plex re-checked right
  before restart) and `github_settings`.
- `notify_failure` opens a "Deploy failed" issue.

If someone is streaming, the deploy postpones itself to the next hour. Never force it. If the user says they've
stopped streaming, a manual dispatch is fine.

```bash
gh run list --workflow deploy.yml --limit 3
gh run watch <id> --exit-status
```

Afterwards, verify the change on the host (`servarr-host` skill) and, for Cloudflare changes, the live state with `cf`
(`servarr-cloudflare` skill). Close any "Deploy failed" issue once fixed, with the cause in a comment.

## Renovate

The hosted **Mend Renovate app** is the only updater (Dependency Dashboard: issue #192). Never run Renovate yourself
or with the user's token. Do not `gh pr update-branch` a Renovate PR; tick the rebase box on #192 instead.
Minor/patch and GitHub Actions majors automerge (one per run, hourly). Terraform and Docker majors open PRs assigned to
the owner. The Mend dashboard must stay at Silent mode OFF / Automated PRs ON (web-only setting). Use the Renovate
MCP tools (`validate_config`, `lint_config`, `explain_config`, `test_package_rules`) for `renovate.json` edits.

## Code scanning (CodeQL, Copilot AI Scan)

- Verify AI Scan findings against the live host and the repo before acting, in both directions. An `ssh-keyscan`
  finding was wrongly dismissed as a Tailscale SSH false positive, while the repo's own drift job already pinned the
  host key successfully.
  Check for counter-evidence before dismissing anything.
- **Fixed** alerts must close through a rescan, never through dismissal: GitHub has no "fixed" dismiss reason, and
  "won't fix" mislabels them. The AI Scan repository scan has no schedule or API, so ask the owner to start it from
  Security > Code scanning after the fix deploys.
- Linking an alert to a PR is web-UI only (alert page, Development, Link a pull request). The REST API rejects
  `linked_pull_requests`, there is no endpoint or GraphQL mutation, and mentioning the alert URL in a PR doesn't link
  it. Put the alert URLs in the PR description and ask the owner to link them.
- Dismiss only real false positives (`false positive`) or risks the owner accepted (`won't fix`), always with a comment.
  Record accepted risks in `docs/TECH_DEBT.md`.
