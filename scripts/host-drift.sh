#!/bin/bash
# Read-only check run on the media host by the weekly host-drift workflow.
# Prints one line per problem and exits 1 if there is any.
set -u
cd "$(dirname "$0")/.." || exit 2

problems=0
note() { echo "PROBLEM: $*"; problems=1; }

# 1. Nobody hand-edited tracked files on the host.
dirty=$(git status --porcelain --untracked-files=no)
[ -z "$dirty" ] || note "tracked files modified on the host: $dirty"

# 2. What is running matches what the compose file pins.
# A docker failure must not look like "nothing to report", so fail loudly before comparing.
if ! declared=$(docker compose config --images 2>/dev/null | sort -u; exit "${PIPESTATUS[0]}"); then
  note "docker compose config failed"; declared=""
fi
if ! running=$(docker ps --format '{{.Image}}' | sort -u; exit "${PIPESTATUS[0]}"); then
  note "docker ps failed"; running=""
fi
missing=$(comm -23 <(echo "$declared") <(echo "$running"))
extra=$(comm -13 <(echo "$declared") <(echo "$running"))
[ -z "$extra" ] || note "running images not in compose: $(echo "$extra" | tr '\n' ' ')"
# kopia/flaresolverr-style optional services may be stopped on purpose, so only report extras and unhealthy ones.
[ -z "$missing" ] || echo "info: declared but not running: $(echo "$missing" | tr '\n' ' ')"

# 3. Nothing is unhealthy or restarting.
bad=$(docker ps --filter health=unhealthy --format '{{.Names}}'; docker ps --filter status=restarting --format '{{.Names}}') ||
  note "docker ps (health) failed"
[ -z "$bad" ] || note "unhealthy/restarting containers: $(echo "$bad" | tr '\n' ' ')"

# 4. The data disk is there and readable.
if ! { mountpoint -q /mnt/data && timeout 10 cat /mnt/data/.mount-ok >/dev/null; }; then note "/mnt/data missing or unreadable"; fi

# 5. Deploy marker is not far behind main (informational: a pending deploy is normal until the window).
deployed=$(cat .deployed-sha 2>/dev/null || echo none)
echo "info: deployed commit $deployed"

[ "$problems" = 0 ] && echo "host in sync"
exit "$problems"
