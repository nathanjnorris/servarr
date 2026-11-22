#!/usr/bin/env bash
# Checks that this machine has every tool, login and connection Claude needs to maintain servarr.
#   bash .claude/skills/servarr-doctor/scripts/doctor.sh          # full check (logins, network, host SSH)
#   bash .claude/skills/servarr-doctor/scripts/doctor.sh --quick  # presence only, no network (SessionStart hook)
# Read-only. Never prints a token. Exit 0 = all good, 1 = something is missing (the report says what and how to fix).
set -u
quick=false; [ "${1:-}" = "--quick" ] && quick=true
HOST=192.168.8.10
missing=0
ok()   { $quick || printf '  ok    %s\n' "$*"; }
miss() { printf '  MISSING %s\n' "$*"; missing=1; }
warn() { printf '  warn  %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
# check "<ok message>" <fail function> "<fail message>" -- command...   (if/else, not A && B || C)
check() { local m=$1 f=$2 fm=$3; shift 4; if "$@" >/dev/null 2>&1; then ok "$m"; else "$f" "$fm"; fi; }

$quick || echo "== CLIs"
tool() { # name, why, install hint
  if have "$1"; then ok "$1"; else miss "$1: $2 (install: $3)"; fi
}
tool git        "everything"                                "xcode-select --install / apt install git"
tool gh         "PRs, reviews, Actions, code scanning API"  "brew install gh && gh auth login"
tool jq         "parsing gh/API output"                     "brew install jq"
tool python3    "helper scripts"                            "brew install python"
tool terraform  "fmt/validate locally (CI pins 1.17.2)"     "brew install hashicorp/tap/terraform"
tool docker     "compose config check, terraform-docs image, Terraform MCP server" "Docker Desktop / OrbStack"
tool shellcheck "Static checks parity"                      "brew install shellcheck"
tool actionlint "Static checks parity"                      "brew install actionlint"
tool cf         "read-only Cloudflare verification"         "npm i -g cf  (github.com/cloudflare/cf)"
tool ssh        "read-only access to the host"              "built in"
tool npx        "skills CLI (tailscale skill updates)"      "brew install node"
tool renovate-mcp "Renovate MCP server (config lint/explain only)" "npm i -g renovate-mcp"
have tailscale || warn "tailscale CLI not found: optional locally (host is reachable on the LAN at $HOST); needed only to reach it off-LAN"

if [ ! -e "$(git rev-parse --show-toplevel 2>/dev/null)/.claude/skills/tailscale/SKILL.md" ]; then
  miss "tailscale skill (.claude/skills/tailscale -> .agents/skills/tailscale): restore with 'git checkout -- .agents .claude' or 'npx skills add https://github.com/tailscale/tailscale-skill'"
fi

if $quick; then
  [ "$missing" = 0 ] || echo "servarr-doctor: tools are missing (above). Run the servarr-doctor skill for the full check."
  exit "$missing"
fi

echo "== Logins"
if gh auth status >/dev/null 2>&1; then
  ok "gh authenticated ($(gh api user --jq .login 2>/dev/null))"
  check "gh has admin on nathanjnorris/servarr" warn "gh lacks admin on the repo (merges/settings may fail)" -- \
    bash -c 'gh api repos/nathanjnorris/servarr --jq .permissions.admin | grep -q true'
else
  miss "gh not logged in: gh auth login"
fi
if have cf; then
  check "cf authenticated" miss "cf not logged in: cf auth login (read-only use)" -- cf auth whoami
fi
cred="$HOME/.terraform.d/credentials.tfrc.json"
if [ -r "$cred" ] && python3 -c "import json,sys;json.load(open(sys.argv[1]))['credentials']['app.terraform.io']['token']" "$cred" 2>/dev/null; then
  code=$(python3 - "$cred" <<'P'
import json,sys,urllib.request
t=json.load(open(sys.argv[1]))['credentials']['app.terraform.io']['token']
r=urllib.request.Request('https://app.terraform.io/api/v2/account/details',headers={'Authorization':'Bearer '+t})
try: print(urllib.request.urlopen(r,timeout=10).status)
except Exception as e: print(getattr(e,'code','ERR'))
P
)
  check "Terraform Cloud token valid" miss "Terraform Cloud token rejected ($code): terraform login" -- test "$code" = 200
else
  miss "Terraform Cloud credentials ($cred): terraform login  (needed to read plan JSON from TFC)"
fi
check "TFE_TOKEN set (Terraform MCP HCP tools)" warn "TFE_TOKEN not exported: Terraform MCP registry tools work, HCP workspace/run tools do not" -- test -n "${TFE_TOKEN:-}"

echo "== Host $HOST"
if ssh -o BatchMode=yes -o ConnectTimeout=8 "nathan@$HOST" true 2>/dev/null; then
  ok "ssh nathan@$HOST"
  # shellcheck disable=SC2016  # expanded on the host, not here
  check "host checkout == .deployed-sha" warn "host HEAD differs from .deployed-sha (deploy pending or failed?)" -- \
    ssh -o BatchMode=yes "nathan@$HOST" 'cd servarr && test "$(git rev-parse HEAD)" = "$(cat .deployed-sha)"'
else
  miss "ssh nathan@$HOST failed: the host uses Tailscale SSH, so this machine must be on the LAN or the tailnet and allowed by the tailnet SSH policy (try: tailscale status; ssh nathan@servarr)"
fi

echo "== Claude Code extensions"
if have claude; then
  mcp=$(claude mcp list 2>/dev/null)
  for s in renovate tailscale-docs terraform; do
    line=$(grep -E "(^|:)$s:" <<<"$mcp" | head -1)
    case "$line" in
      *Connected*) ok "MCP $s" ;;
      "") miss "MCP $s not configured (see .mcp.json / the terraform plugin)" ;;
      *) warn "MCP $s not connected: ${line##*- }" ;;
    esac
  done
  plugins=$(claude plugin list 2>/dev/null)
  for p in terraform commit-commands pr-review-toolkit claude-md-management superpowers; do
    if grep -q "$p@" <<<"$plugins"; then ok "plugin $p"; else miss "plugin $p: accept the plugin prompt from .claude/settings.json, or claude plugin install $p@<marketplace>"; fi
  done
fi

[ "$missing" = 0 ] && echo "All required tooling present." || echo "Fix the MISSING items above before maintaining servarr."
exit "$missing"
