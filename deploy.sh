#!/bin/bash
# Runs on the media host from the Deploy workflow (push to main, hourly, manual; gated by the live Plex check).
# The marker is written only after everything succeeds, so a failed run is retried next window.
set -eu

docker compose pull
docker compose up --build --remove-orphans -d
docker system prune -f
git rev-parse HEAD > .deployed-sha
