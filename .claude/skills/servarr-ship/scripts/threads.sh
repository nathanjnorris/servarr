#!/usr/bin/env bash
# Shows a PR's merge state, reviews (including PENDING ones, which nobody else can see) and review threads.
#   bash .claude/skills/servarr-ship/scripts/threads.sh <pr>
set -euo pipefail
# shellcheck disable=SC2016  # GraphQL variables, not shell
gh api graphql -F n="${1:?pr number}" -f query='query($n:Int!){repository(owner:"nathanjnorris",name:"servarr"){pullRequest(number:$n){
  mergeStateStatus
  reviews(first:50){nodes{author{login} state body}}
  reviewThreads(first:100){nodes{isResolved path line comments(first:5){nodes{author{login} body}}}}}}}' --jq '
  .data.repository.pullRequest
  | "merge state: \(.mergeStateStatus)",
    (.reviews.nodes[] | "REVIEW \(.author.login) \(.state): \(.body[0:300] | gsub("\n";" "))"),
    (.reviewThreads.nodes[] | "THREAD resolved=\(.isResolved) \(.path):\(.line // "-") replies=\(.comments.nodes | length - 1)\n  \(.comments.nodes[0].author.login): \(.comments.nodes[0].body[0:400] | gsub("\n";" "))")'
