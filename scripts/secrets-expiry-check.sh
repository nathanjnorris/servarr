#!/usr/bin/env bash
# Reads the inventory table in docs/SECRETS.md and reports any secret whose "Review by" date is within
# WARN_DAYS (default 30) or already past, and any row whose date is not a real date.
# Exit 0: nothing due. Exit 1: something is due (report on stdout). Read-only.
set -euo pipefail

FILE="${1:-docs/SECRETS.md}"
WARN_DAYS="${WARN_DAYS:-30}"
[ -r "$FILE" ] || { echo "ERROR: cannot read $FILE"; exit 2; }
rows=$(grep -cE '^\| `' "$FILE" || true)
[ "$rows" -gt 0 ] || { echo "ERROR: no inventory rows found in $FILE (table format changed?)"; exit 2; }
now=$(date -u +%s)
status=0

to_epoch() { date -u -d "$1" +%s 2>/dev/null || date -u -j -f %Y-%m-%d "$1" +%s 2>/dev/null; }

# Table rows: | name | store | used by | rotate | YYYY-MM-DD or text |
while IFS= read -r line; do
  name=$(awk -F'|' '{gsub(/^ +| +$/,"",$2); print $2}' <<<"$line")
  last=$(awk -F'|' '{gsub(/^ +| +$/,"",$(NF-1)); print $(NF-1)}' <<<"$line")
  if [[ "$last" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    due=$(to_epoch "$last") || { echo "BAD DATE: $name has '$last'"; status=1; continue; }
    days=$(( (due - now) / 86400 ))
    if (( days < 0 )); then
      echo "OVERDUE: $name was due $last ($(( -days )) days ago)"; status=1
    elif (( days <= WARN_DAYS )); then
      echo "DUE SOON: $name is due $last (in $days days)"; status=1
    fi
  else
    echo "NO DATE: $name has no confirmed review date ('$last')"; status=1
  fi
done < <(grep -E '^\| `' "$FILE")

exit "$status"
