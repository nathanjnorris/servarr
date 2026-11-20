#!/bin/bash
# Runs on the media host every minute (systemd timer, see setup.sh).
# If the data disk disappears or goes unreadable while containers are running, stop every container
# that bind-mounts it. That is what protects Plex and the arr apps from "seeing" an empty library and
# marking everything missing (the 2026-11-15 incident). It never starts anything; recovery is manual.
set -u

MOUNT=/mnt/data
CANARY="$MOUNT/.mount-ok"

if mountpoint -q "$MOUNT" && timeout 10 test -f "$CANARY"; then
  exit 0
fi

mapfile -t victims < <(
  docker ps -q | xargs -r docker inspect --format '{{.Name}} {{range .Mounts}}{{.Source}} {{end}}' |
    awk -v m="$MOUNT" 'index($0, m) { sub("^/", "", $1); print $1 }'
)

[ "${#victims[@]}" -gt 0 ] || exit 0

logger -t data-mount-guard "$MOUNT is missing or unreadable; stopping: ${victims[*]}"
docker stop "${victims[@]}" >/dev/null
