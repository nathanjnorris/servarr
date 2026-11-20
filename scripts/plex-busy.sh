#!/bin/bash
# Runs on the media host. Exit 0 = Plex is idle (or unreachable), exit 10 = someone is streaming.
# The deploy workflow uses this so a restart never interrupts viewing.
set -eu

count=$(docker exec -i plex sh -s <<'INNER' 2>/dev/null || true
TOK=$(grep -o 'PlexOnlineToken="[^"]*' "/config/Library/Application Support/Plex Media Server/Preferences.xml" | cut -d'"' -f2)
curl -s -m 10 -H "X-Plex-Token: $TOK" http://localhost:32400/status/sessions
INNER
)

active=$(printf '%s' "$count" | grep -o 'MediaContainer size="[0-9]*"' | grep -o '[0-9]*' || true)

if [ -z "$active" ]; then
  echo "Plex did not answer; treating as idle"
  exit 0
fi

if [ "$active" -gt 0 ]; then
  echo "Plex has $active active session(s)"
  exit 10
fi

echo "Plex is idle"
