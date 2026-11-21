#!/usr/bin/env bash
# Enforces Conventional Commits (https://www.conventionalcommits.org) on a pull request's title and on every
# commit it adds:   <type>(<optional scope>)<optional !>: <description>
#   PR_TITLE=... bash scripts/conventional-check.sh <base-sha> <head-sha>
#   bash scripts/conventional-check.sh --self-test
# Merge commits are skipped (the PR title is what matters for those). Exit 1 lists every offender.
set -euo pipefail

TYPES='feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'
PATTERN="^(${TYPES})(\\([a-z0-9._/-]+\\))?!?: .+"

valid() { [[ "$1" =~ $PATTERN ]]; }

if [ "${1:-}" = "--self-test" ]; then
  fail=0
  for ok in "feat: add thing" "fix(deploy): stop the 403" "chore(deps): update x" "ci!: drop old trigger" "docs: note"; do
    valid "$ok" || { echo "SELF-TEST: should be valid: $ok"; fail=1; }
  done
  for bad in "Add thing" "fix:no space" "Feat: capital" "fix(): empty scope" "wip" "feat add"; do
    valid "$bad" && { echo "SELF-TEST: should be invalid: $bad"; fail=1; }
  done
  [ "$fail" = 0 ] && echo "self-test ok"
  exit "$fail"
fi

base=${1:?base sha}
head=${2:?head sha}
bad=0

if [ -n "${PR_TITLE:-}" ]; then
  if ! valid "$PR_TITLE"; then
    echo "PR title is not a conventional commit: $PR_TITLE"
    bad=1
  fi
fi

# Capture first so a failing git log (bad or missing SHA) aborts the script instead of looking like "no commits".
commits=$(git log --no-merges --format='%H%x09%s' "$base..$head")
while IFS=$'\t' read -r sha subject; do
  [ -n "$sha" ] || continue
  if ! valid "$subject"; then
    echo "Commit ${sha:0:7} is not a conventional commit: $subject"
    bad=1
  fi
done <<< "$commits"

if [ "$bad" != 0 ]; then
  echo
  echo "Expected: <type>(<optional scope>)<optional !>: <description>, with type one of: ${TYPES//|/, }"
  echo "Add ! before the colon for a breaking change, e.g. 'feat!: drop the old trigger'"
  echo "Examples: 'feat: add data mount guard', 'fix(deploy): stop failing on a 403', 'chore(deps): update sonarr'"
fi
exit "$bad"
