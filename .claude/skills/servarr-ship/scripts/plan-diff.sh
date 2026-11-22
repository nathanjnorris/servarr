#!/usr/bin/env bash
# Waits for a PR's "Terraform plan" check on a given head commit, then downloads that run's plan JSON from Terraform
# Cloud and prints every resource change that is not a no-op, plus replace paths.
#   bash .claude/skills/servarr-ship/scripts/plan-diff.sh <pr> [head-sha]
# Pin the SHA you pushed: without it you can read a stale plan from an earlier commit.
# Needs gh and a Terraform Cloud token in ~/.terraform.d/credentials.tfrc.json (terraform login). Read-only.
set -euo pipefail
REPO=nathanjnorris/servarr
pr=${1:?pr number}
head=${2:-$(gh pr view "$pr" -R "$REPO" --json headRefOid --jq .headRefOid)}
umask 077   # the plan JSON holds infrastructure identifiers: keep it private to this user
out=$(mktemp "${TMPDIR:-/tmp}/servarr-plan-$pr-XXXXXX")

conclusion() {
  gh api "repos/$REPO/commits/$head/check-runs" \
    --jq '[.check_runs[]|select(.name=="Terraform plan" and .status=="completed")|.conclusion]|first // empty'
}
gh api "repos/$REPO/commits/$head" --jq .sha >/dev/null || { echo "Commit $head not found on GitHub (not pushed? typo?)"; exit 1; }
deadline=$(( $(date +%s) + 1800 ))
until c=$(conclusion) && [ -n "$c" ]; do
  [ "$(date +%s)" -lt "$deadline" ] || { echo "No completed Terraform plan on ${head:0:7} after 30 minutes"; exit 1; }
  sleep 20
done
echo "Terraform plan check on ${head:0:7}: $c"
[ "$c" = success ] || { echo "Plan did not succeed ($c). skipped = no Terraform change detected, or the README/fmt job failed first; otherwise read the job log: gh run view --log-failed"; exit 1; }

job=$(gh api "repos/$REPO/commits/$head/check-runs" --jq '[.check_runs[]|select(.name=="Terraform plan")][0].id')
run=$(gh api "repos/$REPO/actions/jobs/$job/logs" | grep -oE 'runs/run-[A-Za-z0-9]+' | head -1 | sed 's|runs/||')
[ -n "$run" ] || { echo "No TFC run id in the job log (plan skipped? README not regenerated?)"; exit 1; }
echo "TFC run: $run"

python3 - "$run" "$out" <<'P'
import json, os, sys, urllib.request, collections
run, out = sys.argv[1], sys.argv[2]
tok = json.load(open(os.path.expanduser('~/.terraform.d/credentials.tfrc.json')))['credentials']['app.terraform.io']['token']
def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers={'Authorization': 'Bearer ' + tok}), timeout=60).read()
plan = json.loads(get(f'https://app.terraform.io/api/v2/runs/{run}'))['data']['relationships']['plan']['data']['id']
data = get(f'https://app.terraform.io/api/v2/plans/{plan}/json-output')
open(out, 'wb').write(data)
d = json.loads(data); counts = collections.Counter()
for r in d.get('resource_changes', []):
    a = '+'.join(r['change']['actions'])
    if r.get('previous_address'): a += ' (moved from ' + r['previous_address'] + ')'
    if a == 'no-op': continue
    counts[a.split(' ')[0]] += 1
    print(f"{a:10} {r['address']}")
    if r['change'].get('replace_paths'): print('           replace_paths:', r['change']['replace_paths'])
print('summary:', dict(counts) or 'no changes', '| applyable:', d.get('applyable'), '| errored:', d.get('errored'))
print('plan JSON saved to', out, '(contains no secret values; sensitive attributes are redacted by Terraform)')
P
