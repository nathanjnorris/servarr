---
name: servarr-doctor
description: Check that this machine has every CLI, login, MCP server, plugin and network path needed to maintain servarr (gh, terraform, cf, docker, Terraform Cloud token, SSH to 192.168.8.10, Renovate/Terraform MCP). Use at the start of a session on a new computer, when a tool or login fails, or before deploy/merge work.
---

# servarr doctor

Run the check and report what is missing to the user, with the fix for each item:

```bash
bash .claude/skills/servarr-doctor/scripts/doctor.sh          # full: logins, TFC token, host SSH, MCP, plugins
bash .claude/skills/servarr-doctor/scripts/doctor.sh --quick  # presence only (the SessionStart hook runs this)
```

`MISSING` blocks maintenance work. `warn` limits it (say what is degraded). The script is read-only and never
prints tokens.

## What each tool is for, and what to do without it

| Tool | Used for | If missing |
| --- | --- | --- |
| `gh` (logged in as the repo owner, admin) | PRs, review threads, Actions runs, code-scanning alerts, secrets (`gh secret set` from stdin) | Cannot ship. Ask the user to run `! gh auth login`. |
| `terraform` 1.17.x | `terraform fmt -check -recursive`, `terraform validate` (needs `terraform init -backend=false`) | CI still checks; local parity lost. |
| `~/.terraform.d/credentials.tfrc.json` (`terraform login`) | Reading plan JSON from Terraform Cloud (`servarr-ship` skill, `plan-diff.sh`) | Cannot inspect plans beyond the PR comment. Ask the user to run `! terraform login`. Never work around a 401. |
| `docker` | `docker compose config -q`, the pinned terraform-docs image, the Terraform MCP server | README regeneration and Terraform MCP break. |
| `shellcheck`, `actionlint` | Same checks as the required "Static checks" job | CI still checks. |
| `cf` (Cloudflare CLI, `cf auth whoami`) | Read-only verification of Access apps, tunnels, DNS, zone settings | Use the Cloudflare dashboard via the user; never write with `cf`. |
| `ssh nathan@192.168.8.10` | Read-only host inspection (`servarr-host` skill) | Works only on the owner's machine (their personal key is authorised on the host; never copy or commit it). Elsewhere: no direct access. Read Actions logs and ship changes through a PR and the Deploy workflow. Do not run `tailscale up` without asking. |
| `renovate-mcp` | Renovate MCP server: lint/explain/validate `renovate.json` | Edit `renovate.json` carefully by hand; never run Renovate itself. |
| Terraform MCP (terraform plugin, Docker) | Provider resource lookup before any config change | Fall back to registry docs on the web; still record the lookup. |
| `TFE_TOKEN` env var | Terraform MCP's HCP Terraform tools (workspaces, runs) | Registry tools still work; read runs with `plan-diff.sh` instead. |
| tailscale skill (`.claude/skills/tailscale`, vendored) | Tailscale SSH / tailnet questions | `npx skills add https://github.com/tailscale/tailscale-skill` |
| `tailscale-docs` MCP (`.mcp.json`) | Tailscale docs search | Optional; it often fails with ECONNRESET. Use the tailscale skill or WebFetch tailscale.com/docs. |

The GitHub plugin's MCP server is not required. Use `gh` instead; that MCP usually fails with "Authorization header is
badly formatted" unless a Copilot token is configured.
