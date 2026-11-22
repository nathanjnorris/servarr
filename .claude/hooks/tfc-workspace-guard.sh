#!/usr/bin/env bash
# PreToolUse hook for the Terraform MCP. Enforces "write only to the servarr workspace": permission rules cannot look
# at arguments, so this checks every call to a mutating Terraform MCP tool and blocks (exit 2) unless it targets org
# nathanjnorris-org and workspace servarr (by name or id), and does not rename it. Read tools pass through. Fails
# closed: unknown argument shapes, unparseable input or a missing jq are blocked.
set -u
ORG=nathanjnorris-org
WS_NAME=servarr
WS_ID="ws-XG6CTSfjg3x13dv6"

input=$(cat)
command -v jq >/dev/null 2>&1 || { echo "tfc-workspace-guard: jq is required; blocking" >&2; exit 2; }
tool=$(jq -r '.tool_name // empty' <<<"$input") || { echo "tfc-workspace-guard: unreadable hook input; blocking" >&2; exit 2; }
name=${tool#mcp__plugin_terraform_terraform__}

case "$name" in
  # Read-only tools: nothing to check.
  list_*|get_*|search_*|read_*) exit 0 ;;
esac

block() { echo "tfc-workspace-guard: blocked $name: $1. Agents may only change the servarr workspace in $ORG (CLAUDE.md, \"Terraform Cloud workspace\")." >&2; exit 2; }

org=$(jq -r '.tool_input.terraform_org_name // empty' <<<"$input")
ws=$(jq -r '.tool_input.workspace_name // .tool_input.workspace_id // empty' <<<"$input")
new_name=$(jq -r '.tool_input.new_name // empty' <<<"$input")

[ "$org" = "$ORG" ] || block "organization is '${org:-<none>}'"
[ "$ws" = "$WS_NAME" ] || [ "$ws" = "$WS_ID" ] || block "workspace is '${ws:-<none>}'"
[ -z "$new_name" ] || block "renaming the workspace is not allowed"
exit 0
