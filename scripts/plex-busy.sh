#!/bin/bash
# Runs on the media host. The deploy workflow uses this so a restart never interrupts viewing.
#   exit 0  = safe: Plex is idle, or the Plex container is not running at all
#   exit 10 = someone is streaming: postpone
#   exit 11 = Plex is running but could not be asked: treat as unsafe and report it
set -eu

if [ "$(docker inspect -f '{{.State.Running}}' plex 2>/dev/null || echo false)" != "true" ]; then
  echo "Plex container is not running; nothing to interrupt"
  exit 0
fi

reply=$(docker exec -i plex sh -s <<'INNER' 2>/dev/null || true
TOK=$(grep -o 'PlexOnlineToken="[^"]*' "/config/Library/Application Support/Plex Media Server/Preferences.xml" | cut -d'"' -f2)
curl -s -m 10 -H "X-Plex-Token: $TOK" http://localhost:32400/status/sessions
INNER
)

active=$(printf '%s' "$reply" | grep -o 'MediaContainer size="[0-9]*"' | grep -o '[0-9]*' || true)

if [ -z "$active" ]; then
  echo "Plex is running but did not answer the session check; refusing to treat that as idle"
  exit 11
fi

if [ "$active" -gt 0 ]; then
  echo "Plex has $active active session(s)"
  exit 10
fi

echo "Plex is idle"
