#!/usr/bin/env bash
# Publishes the "Review replies" commit status for ONE pull request and exits 1 only if that PR is in "failure".
#   GH_TOKEN=... GITHUB_REPOSITORY=owner/repo bash scripts/review-replies-check.sh <pr-number> <head-sha>
# States: pending  = Copilot has not reviewed yet, or CodeQL has not finished (blocks merge, not an error)
#         failure  = a resolved review thread has no comment from anyone but its opener
#         success  = Copilot reviewed, CodeQL finished, every resolved thread has a reply
# Any API/jq error aborts with a non-zero exit before a status is posted (fails closed).
set -euo pipefail

pr=${1:?pull request number}
sha=${2:?head commit sha}
owner=${GITHUB_REPOSITORY%/*}
repo=${GITHUB_REPOSITORY#*/}

# shellcheck disable=SC2016  # $o/$r/$n/$endCursor are GraphQL variables, not shell
unanswered=$(gh api graphql --paginate -f query='
  query($o:String!,$r:String!,$n:Int!,$endCursor:String){repository(owner:$o,name:$r){pullRequest(number:$n){
    reviewThreads(first:100,after:$endCursor){pageInfo{hasNextPage endCursor}
      nodes{isResolved path comments(first:100){nodes{author{login}}}}}}}}' \
  -f o="$owner" -f r="$repo" -F n="$pr" \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[]
        | select(.isResolved and ([.comments.nodes[].author.login] | unique | length) < 2)
        | .path')

# The login match tolerates a "[bot]" suffix (GraphQL omits it, REST adds it).
# shellcheck disable=SC2016
copilot=$(gh api graphql --paginate -f query='
  query($o:String!,$r:String!,$n:Int!,$endCursor:String){repository(owner:$o,name:$r){pullRequest(number:$n){
    reviews(first:100,after:$endCursor){pageInfo{hasNextPage endCursor}nodes{author{login}}}}}}' \
  -f o="$owner" -f r="$repo" -F n="$pr" \
  --jq '.data.repository.pullRequest.reviews.nodes[].author.login | select(startswith("copilot-pull-request-reviewer"))' | wc -l | tr -d ' ')

scanning=$(gh api --paginate "repos/$GITHUB_REPOSITORY/commits/$sha/check-runs?per_page=100" \
  --jq '.check_runs[] | select(.name == "CodeQL" or (.name | startswith("Analyze"))) | .status' | sort -u | tr '\n' ' ')
case "$scanning" in
  "") scanning=missing ;;
  "completed ") scanning=finished ;;
  *) scanning=running ;;
esac

rc=0
if [ "$copilot" = "0" ]; then
  state=pending; desc="Waiting for the Copilot review"
elif [ "$scanning" != "finished" ]; then
  state=pending; desc="Waiting for CodeQL ($scanning)"
elif [ -n "$unanswered" ]; then
  state=failure; rc=1
  desc="Resolved without a reply: $(echo "$unanswered" | sort -u | tr '\n' ' ' | cut -c1-100)"
else
  state=success; desc="Copilot reviewed, CodeQL done, every resolved thread has a reply"
fi

echo "#$pr $state: $desc"
gh api "repos/$GITHUB_REPOSITORY/statuses/$sha" \
  -f state="$state" -f context="Review replies" -f description="$desc" \
  -f target_url="${GITHUB_SERVER_URL:-https://github.com}/$GITHUB_REPOSITORY/actions/runs/${GITHUB_RUN_ID:-0}" >/dev/null
exit "$rc"
