#!/usr/bin/env bash
# GitHub Copilot sessionStart hook (.github/hooks/servarr.json): the Copilot twin of Claude Code's SessionStart hook in
# .claude/settings.json. Runs the servarr-doctor quick check and hands any report to the agent as additionalContext
# (Copilot ignores plain-text hook output). Never fails the session.
set -u
root=$(cd "$(dirname "$0")/../.." && pwd)
report=$(bash "$root/.claude/skills/servarr-doctor/scripts/doctor.sh" --quick 2>&1)
if [ -n "${COPILOT_AGENT_PROMPT+x}" ] || [ "${GITHUB_ACTIONS:-}" = true ]; then
  report="${report:+$report
}servarr: this is a Copilot cloud agent sandbox. There is no SSH to the host, no cf login and outbound network is firewalled: follow CLAUDE.md rule 10 for machines other than the owner's (workflow logs, changes only through a PR)."
fi
[ -n "$report" ] || { echo '{}'; exit 0; }
python3 -c 'import json,sys; print(json.dumps({"additionalContext": sys.stdin.read()}))' <<<"$report" 2>/dev/null || echo '{}'
