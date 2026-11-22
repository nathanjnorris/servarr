#!/usr/bin/env python3
"""Reply to every UNRESOLVED review thread on a PR, then resolve it.

    python3 .claude/skills/servarr-ship/scripts/reply-threads.py <pr> <replies.json>

replies.json is a JSON list of strings, one per unresolved thread, in the order threads.sh prints them.
Replies go through the REST endpoint (POST /pulls/{pr}/comments/{id}/replies). Do NOT use GraphQL
addPullRequestReviewThreadReply: it files the reply into an unsubmitted PENDING review that nobody else can see,
and the "Review replies" gate then fails. Afterwards the script checks that no PENDING review remains.
"""
import json
import subprocess
import sys

REPO = "nathanjnorris/servarr"


def gh(*args):
    return subprocess.run(["gh", *args], capture_output=True, text=True, check=True).stdout


pr, replies = sys.argv[1], json.load(open(sys.argv[2]))
q = """query($n:Int!){repository(owner:"nathanjnorris",name:"servarr"){pullRequest(number:$n){
  reviewThreads(first:100){pageInfo{hasNextPage} nodes{id isResolved comments(first:1){nodes{databaseId body}}}}}}}"""
conn = json.loads(gh("api", "graphql", "-f", "query=" + q, "-F", "n=" + pr))["data"]["repository"]["pullRequest"]["reviewThreads"]
if conn["pageInfo"]["hasNextPage"]:
    sys.exit("More than 100 review threads: this script does not paginate; nothing posted")
threads = [t for t in conn["nodes"] if not t["isResolved"]]
if len(threads) != len(replies):
    sys.exit(f"{len(threads)} unresolved threads but {len(replies)} replies; nothing posted")

for thread, body in zip(threads, replies):
    first = thread["comments"]["nodes"][0]
    gh("api", "-X", "POST", f"repos/{REPO}/pulls/{pr}/comments/{first['databaseId']}/replies", "-f", "body=" + body)
    gh("api", "graphql", "-f", "query=mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{isResolved}}}",
       "-f", "id=" + thread["id"])
    print("replied + resolved:", first["body"][:70].replace("\n", " "))

pending = gh("api", "graphql", "-F", "n=" + pr, "-f",
             'query=query($n:Int!){repository(owner:"nathanjnorris",name:"servarr"){pullRequest(number:$n){'
             'reviews(states:PENDING,first:5){totalCount}}}}',
             "--jq", ".data.repository.pullRequest.reviews.totalCount").strip()
print("pending reviews:", pending)
if pending != "0":
    sys.exit("A PENDING review exists: submit or delete it, otherwise the replies are invisible")
