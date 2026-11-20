#!/usr/bin/env python3
"""Delete optimised-only copies whose 4K parent no longer exists in Plex.

Plex scans /data/optimised inside the non-4K libraries, so each optimised copy of a 4K title can show
up there as its own item. Maintainerr cleans the 4K item but cannot see the optimised one, so this
script finds items in the non-4K libraries whose every file lives under /data/optimised AND that have
no 4K counterpart (matched by tmdb/tvdb/imdb guid), and deletes them through Plex's own API.

Runs on the media host (needs docker). Dry run unless --apply. Hard guards, because a wrong run
would delete media: refuses if /mnt/data is not mounted, if any 4K library is empty or unreadable,
and only deletes items with a readable guid. Items added in the last MIN_AGE_DAYS days are skipped
(a conversion may still be settling).
"""
import json
import os
import subprocess
import sys
import time

# (non-4K section, its 4K section, plex type)
PAIRS = [(3, 8, 1), (4, 9, 2)]
OPTIMISED_PREFIX = "/data/optimised/"
MIN_AGE_DAYS = 7
DATA_MOUNT = "/mnt/data"
CANARY = os.path.join(DATA_MOUNT, ".mount-ok")
MIN_PARENT_GUID_RATIO = 0.9  # of 4K items must carry a usable id, else metadata looks half-loaded


def guids(item):
    return {g["id"] for g in item.get("Guid", []) if g["id"].split("://")[0] in ("tmdb", "tvdb", "imdb")}


def decide(optimised_only, parents, now=None, min_age_days=MIN_AGE_DAYS):
    """Pure decision: which optimised-only items have no 4K parent and are old enough."""
    now = now or time.time()
    out = []
    for it in optimised_only:
        if guids(it) & parents:
            continue
        if not guids(it):
            continue  # cannot prove the parent is gone without an id
        if now - int(it.get("addedAt", now)) < min_age_days * 86400:
            continue
        out.append(it)
    return out


def plex(path, method="GET"):
    sh = (
        "TOK=$(grep -o 'PlexOnlineToken=\"[^\"]*' '/config/Library/Application Support/Plex Media Server/Preferences.xml' "
        "| cut -d'\"' -f2); "
        f"curl -s -m 60 -o /tmp/out.json -w '%{{http_code}}' -X {method} -H \"X-Plex-Token: $TOK\" "
        f"-H 'Accept: application/json' 'http://localhost:32400{path}'; echo; cat /tmp/out.json"
    )
    res = subprocess.run(["docker", "exec", "plex", "sh", "-c", sh], capture_output=True, text=True)
    code, _, body = res.stdout.partition("\n")
    return code, body


def section_items(sec, typ):
    code, body = plex(f"/library/sections/{sec}/all?type={typ}&includeGuids=1")
    if code != "200":
        raise RuntimeError(f"section {sec}: HTTP {code}")
    return json.loads(body)["MediaContainer"].get("Metadata", [])


def files_of(rating_key):
    code, body = plex(f"/library/metadata/{rating_key}/allLeaves")
    md = json.loads(body)["MediaContainer"].get("Metadata") if code == "200" else None
    if not md:
        code, body = plex(f"/library/metadata/{rating_key}")
        md = json.loads(body)["MediaContainer"].get("Metadata", [])
    return [p["file"] for m in md for me in m.get("Media", []) for p in me.get("Part", [])]


def main():
    apply = "--apply" in sys.argv
    if not os.path.ismount(DATA_MOUNT):
        sys.exit(f"{DATA_MOUNT} is not mounted; refusing to run")
    try:
        with open(CANARY) as fh:  # actually read it: proves this is the real data disk and it is readable
            fh.read(1)
    except OSError as err:
        sys.exit(f"cannot read {CANARY} ({err}); refusing to run")
    deletions = []
    for non4k, k4, typ in PAIRS:
        parents_items = section_items(k4, typ)
        if not parents_items:
            sys.exit(f"4K section {k4} returned no items; refusing to run (would look like every parent is gone)")
        parents = set().union(*(guids(i) for i in parents_items))
        with_ids = sum(1 for i in parents_items if guids(i))
        if not parents or with_ids / len(parents_items) < MIN_PARENT_GUID_RATIO:
            sys.exit(
                f"4K section {k4}: only {with_ids}/{len(parents_items)} items have a tmdb/tvdb/imdb id; "
                "refusing to run (metadata looks incomplete)"
            )
        candidates = []
        for it in section_items(non4k, typ):
            fs = files_of(it["ratingKey"])
            if fs and all(f.startswith(OPTIMISED_PREFIX) for f in fs):
                candidates.append(it)
        deletions += decide(candidates, parents)
    print(f"{len(deletions)} optimised-only item(s) with no 4K parent")
    for it in deletions:
        print(f"  {it['title']} (ratingKey {it['ratingKey']})")
    failed = 0
    if apply:
        for it in deletions:
            code, _ = plex(f"/library/metadata/{it['ratingKey']}", "DELETE")
            if code.startswith("2"):
                print(f"deleted {it['title']}: HTTP {code}")
            else:
                failed += 1
                print(f"FAILED to delete {it['title']}: HTTP {code}", file=sys.stderr)
        if failed:
            sys.exit(f"{failed} deletion(s) failed; they will be retried on the next run")
    elif deletions:
        print("dry run; pass --apply to delete")


if __name__ == "__main__":
    main()
