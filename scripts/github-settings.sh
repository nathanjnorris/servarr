#!/usr/bin/env bash
# Idempotent: makes the GitHub repo settings that Terraform CANNOT manage match what is declared here.
# Run by the deploy workflow on every deployment (job "Settings Terraform cannot manage"), and safe to run by hand:
#   GH_TOKEN=<token> bash scripts/github-settings.sh
# Only PATCHes when the live value differs. Every entry here must also be listed in NON_TERRAFORM_CONFIG.md.
# Before adding anything, check the Terraform GitHub provider first (Terraform MCP: search_providers) and prefer a resource.
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-nathanjnorris/servarr}"
: "${GH_TOKEN:?GH_TOKEN (a token with admin on the repo) is required}"

status=0

# ensure_json <label> <METHOD> <path> <field=value ...>
# Compares each field of the live JSON object (GET path) with the wanted value and sends only the differing
# fields with METHOD (PATCH or PUT) to the same path.
ensure_json() {
  local label=$1 method=$2 path=$3; shift 3
  local live changes=() pair key want have
  # The caller uses `|| status=1`, which turns errexit off inside this function, so every call is checked explicitly.
  live=$(gh api "$path") || { echo "$label: could not read $path" >&2; return 1; }
  for pair in "$@"; do
    key=${pair%%=*}; want=${pair#*=}
    have=$(jq -r --arg k "$key" '.[$k]' <<<"$live") || return 1
    if [ "$have" != "$want" ]; then
      echo "$label: $key is '$have', want '$want'"
      changes+=(-f "$key=$want")
    fi
  done
  if [ "${#changes[@]}" -eq 0 ]; then
    echo "$label: already correct"
    return 0
  fi
  gh api -X "$method" "$path" "${changes[@]}" >/dev/null || { echo "$label: update FAILED" >&2; return 1; }
  echo "$label: updated"
}

# AI Scan (code scanning). No Terraform resource exists in integrations/github 6.13.0.
ensure_json "AI Scan" PATCH "repos/$REPO/code-scanning/ai-scan" pr_scan=enabled repository_scan=enabled || status=1

# Which actors need a manual approval before their workflow runs start. "all_external_contributors" also held back
# runs started by the Copilot reviewer app (every review comment became an action_required run). The owner approved
# changing this to first_time_contributors on 2026-11-21. No attribute for it exists in
# github_actions_repository_permissions (integrations/github 6.13.0, checked via Terraform MCP).
ensure_json "Fork PR approval policy" PUT "repos/$REPO/actions/permissions/fork-pr-contributor-approval" approval_policy=first_time_contributors || status=1

exit "$status"
