#!/usr/bin/env bash
# Publishes the "Review replies" commit status for ONE pull request and exits 1 only if that PR is in "failure".
#   GH_TOKEN=... GITHUB_REPOSITORY=owner/repo [WAIT_MINUTES=15] bash scripts/review-replies-check.sh <pr-number> <head-sha>
# States: pending  = Copilot has not reviewed yet, or CodeQL / the AI Scan PR review ("github-advanced-security" check
#                    run, which posts its findings as review threads) has not finished (blocks merge, not an error)
#         failure  = a resolved review thread has no comment from anyone but its opener
#         success  = Copilot reviewed, CodeQL finished, every resolved thread has a reply
# With WAIT_MINUTES > 0 (the pull_request job) a pending state is re-checked every 30 seconds until it resolves or the
# time is up, so the status flips as soon as CodeQL or Copilot finishes instead of waiting for the next sweep.
# Any API/jq error aborts with a non-zero exit and posts state=error first (fails closed).
set -euo pipefail

pr=${1:?pull request number}
sha=${2:?head commit sha}
wait_minutes=${WAIT_MINUTES:-0}
owner=${GITHUB_REPOSITORY%/*}
repo=${GITHUB_REPOSITORY#*/}

# If anything below fails, replace any earlier status (for example an old "success") with "error" so a stale pass
# can never keep satisfying the required check. Best effort: if posting also fails, the original error still exits.
# shellcheck disable=SC2329  # invoked via trap
post_error() {
  gh api "repos/$GITHUB_REPOSITORY/statuses/$sha" -f state=error -f context="Review replies" \
    -f description="The check could not run; it will retry on the next sweep" >/dev/null 2>&1 || true
}
trap post_error ERR

post_status() {
  gh api "repos/$GITHUB_REPOSITORY/statuses/$sha" \
    -f state="$1" -f context="Review replies" -f description="$2" \
    -f target_url="${GITHUB_SERVER_URL:-https://github.com}/$GITHUB_REPOSITORY/actions/runs/${GITHUB_RUN_ID:-0}" >/dev/null
}

# Dependency bots: Copilot does not review their PRs and CodeQL is skipped for them (neutral), so those two
# requirements can never be met. For them the gate only requires that no resolved thread is unanswered; they are
# still held back by the required Terraform plan and Static checks, and the policy for what auto-merges lives in
# renovate.json. Everything else (humans, me) needs a Copilot review and finished CodeQL.
is_dependency_bot() {
  local author
  author=$(gh api "repos/$GITHUB_REPOSITORY/pulls/$pr" --jq '.user.login')
  [[ "$author" =~ ^(dependabot|renovate)\[bot\]$ ]]
}

# Sets: state, desc
evaluate() {
  local unanswered copilot scanning bot=0
  if is_dependency_bot; then bot=1; fi
  # shellcheck disable=SC2016  # $o/$r/$n/$endCursor are GraphQL variables, not shell
  unanswered=$(gh api graphql --paginate -f query='
    query($o:String!,$r:String!,$n:Int!,$endCursor:String){repository(owner:$o,name:$r){pullRequest(number:$n){
      reviewThreads(first:100,after:$endCursor){pageInfo{hasNextPage endCursor}
        nodes{isResolved path comments(first:100){nodes{author{__typename login}}}}}}}}' \
    -f o="$owner" -f r="$repo" -F n="$pr" \
    --jq '.data.repository.pullRequest.reviewThreads.nodes[]
          | select(.isResolved and ([.comments.nodes[].author.login] | unique | length) < 2)
          | .path')

  # Only the real Copilot bot counts: a Bot-type account with the exact login (GraphQL omits the "[bot]" suffix),
  # so a user account whose name merely starts with it cannot satisfy the gate.
  # shellcheck disable=SC2016
  copilot=$(gh api graphql --paginate -f query='
    query($o:String!,$r:String!,$n:Int!,$endCursor:String){repository(owner:$o,name:$r){pullRequest(number:$n){
      reviews(first:100,after:$endCursor){pageInfo{hasNextPage endCursor}nodes{author{__typename login}}}}}}' \
    -f o="$owner" -f r="$repo" -F n="$pr" \
    --jq '.data.repository.pullRequest.reviews.nodes[].author | select(.__typename == "Bot" and .login == "copilot-pull-request-reviewer") | .login' | wc -l | tr -d ' ')

  scanning=$(gh api --paginate "repos/$GITHUB_REPOSITORY/commits/$sha/check-runs?per_page=100" \
    --jq '.check_runs[] | select(.name == "CodeQL" or (.name | startswith("Analyze")) or .name == "github-advanced-security") | .status' | sort -u | tr '\n' ' ')
  case "$scanning" in
    "") scanning=missing ;;
    "completed ") scanning=finished ;;
    *) scanning=running ;;
  esac

  if [ "$bot" = 0 ] && [ "$copilot" = "0" ]; then
    state=pending; desc="Waiting for the Copilot review"
  elif [ "$bot" = 0 ] && [ "$scanning" != "finished" ]; then
    state=pending; desc="Waiting for CodeQL and the AI Scan PR review ($scanning)"
  elif [ -n "$unanswered" ]; then
    state=failure
    desc="Resolved without a reply: $(echo "$unanswered" | sort -u | tr '\n' ' ' | cut -c1-100)"
  else
    if [ "$bot" = 1 ]; then
      state=success; desc="Dependency bot PR: no unanswered resolved threads (Copilot and CodeQL do not apply)"
    else
      state=success; desc="Copilot reviewed, CodeQL and AI Scan done, every resolved thread has a reply"
    fi
  fi
}

deadline=$(( $(date +%s) + wait_minutes * 60 ))
last=""
while :; do
  evaluate
  if [ "$state:$desc" != "$last" ]; then
    echo "#$pr $state: $desc"
    post_status "$state" "$desc"
    last="$state:$desc"
  fi
  [ "$state" = pending ] && [ "$(date +%s)" -lt "$deadline" ] || break
  sleep 30
done

# Intentional exit: drop the ERR trap first, otherwise a failing check would overwrite its own "failure" status with "error".
trap - ERR
if [ "$state" = failure ]; then exit 1; fi
exit 0
