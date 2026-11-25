#!/usr/bin/env bash
# PreToolUse guard for renovate-mcp's dry_run. Local dry runs are allowed (owner, 2026-11-25): renovate-mcp exports no
# token and opens no PRs under platform=local. Anything that would make it act as a real platform client is blocked
# (exit 2): platform github/gitlab, an endpoint, token, repository or hostRules argument, a repoPath other than
# this repository, or a non-local RENOVATE_PLATFORM in the environment. Fails closed on unreadable input.
# Claude Code calls it directly (.claude/settings.json); GitHub Copilot calls it through .github/hooks/permission-policy.py.
set -u
input=$(cat)
command -v jq >/dev/null 2>&1 || { echo "renovate-guard: jq is required; blocking" >&2; exit 2; }
platform=$(jq -r '.tool_input.platform // "local"' <<<"$input") || { echo "renovate-guard: unreadable hook input; blocking" >&2; exit 2; }
remote=$(jq -r '[.tool_input.endpoint, .tool_input.token, .tool_input.repository] | map(select(. != null and . != "")) | length' <<<"$input")
host_rules=$(jq -r '.tool_input.hostRules // [] | length' <<<"$input")
repo_path=$(jq -r '.tool_input.repoPath // empty' <<<"$input")
root=$(cd "$(dirname "$0")/../.." && pwd -P)

block() { echo "renovate-guard: blocked dry_run: $1. Only local dry runs are allowed (CLAUDE.md rule 7)." >&2; exit 2; }
[ "$platform" = local ] || block "platform is '$platform'"
[ "$remote" = 0 ] || block "endpoint, token or repository given"
[ "$host_rules" = 0 ] || block "hostRules can carry registry credentials"
# Only this repository: a dry run elsewhere would read (and copy) arbitrary local files.
[ -n "$repo_path" ] && [ -d "$repo_path" ] && [ "$(cd "$repo_path" && pwd -P)" = "$root" ] || block "repoPath must be this repository ($root)"
# renovate-mcp falls back to RENOVATE_PLATFORM from its environment; .mcp.json pins it to local, this is the backstop.
[ -z "${RENOVATE_PLATFORM:-}" ] || [ "$RENOVATE_PLATFORM" = local ] || block "RENOVATE_PLATFORM is '$RENOVATE_PLATFORM' in the environment"
exit 0
