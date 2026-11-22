---
name: servarr-host
description: Inspect and diagnose the live media host at 192.168.8.10 (Docker containers, Plex streaming state, data disk and mount guard, SMART, systemd timers, deploy marker, logs) over read-only SSH. Use for health checks, "is X working", post-deploy verification, or before any change that touches the host.
---

# Operating the live host

Host facts, hand-applied settings and app-DB settings are in `docs/HOST.md`. Read that first.

## Golden rules

- **SSH access exists only on the owner's machine.** It works because the owner's personal SSH key is authorised on
  the host. Never copy, print or commit it, and never add keys. If `ssh nathan@192.168.8.10 true` fails, you have
  no host access: use Actions logs (`gh run view --log`), and ship every change via a PR and the Deploy workflow.
- **SSH is read-only.** `ssh nathan@192.168.8.10 '<command>'` is for looking. Every host change goes through a PR:
  `setup.sh` (runs as root on every deploy), `docker-compose.yml`, or a script the deploy runs. If something truly can
  only be done by hand with sudo, write the exact idempotent commands for the user to paste. Do not run sudo yourself.
- **Never interrupt Plex streaming.** Check `bash ~/servarr/scripts/plex-busy.sh` on the host before anything that
  restarts containers. Exit codes: 0 idle, 10 streaming, 11 unknown (treat as busy).
- **Never edit the Plex DB.** Use the Plex API (token in `config/plex-config/.../Preferences.xml`, read it on the host
  and never print it).
- **Never edit Maintainerr config or rules** without explicit approval.
- **Never write to the Uptime Kuma SQLite DB.** Inspect it read-only; the owner changes monitors in the UI.
- Back up before any change (`/home/nathan/backups/<date>-<reason>/`).
- Do not reboot while a SMART extended test is running. Do not run `tailscale up` on the user's machine without asking.

## Health check (copy-paste)

```bash
ssh nathan@192.168.8.10 '
  cd servarr; echo "deployed $(cut -c1-7 .deployed-sha)  head $(git rev-parse --short HEAD)"; git status --porcelain --untracked-files=no
  docker ps --format "{{.Names}}\t{{.Status}}" | sort
  docker ps -a --filter status=exited --filter status=restarting --format "PROBLEM {{.Names}} {{.Status}}"
  findmnt /mnt/data; cat /mnt/data/.mount-ok >/dev/null && echo canary-ok
  systemctl list-timers --no-pager data-mount-guard.timer optimised-cleanup.timer | head -3
  systemctl --failed --no-pager | head
  df -h / /mnt/data | tail -2
  bash scripts/plex-busy.sh; echo "plex-busy=$?"'
```

Then the public side, without credentials:
- `curl -sI https://status.nathanjn.com` should redirect to the public status page.
- Access-protected apps (for example `https://sonarr.nathanjn.com`) should redirect to the Cloudflare Access login.

## Diagnosing

| Symptom | Look at |
| --- | --- |
| Container restarting/unhealthy | `docker logs --tail 100 <name>`, `docker inspect <name> --format '{{json .State.Health}}'` |
| Many media containers stopped at once | `journalctl -t data-mount-guard --since -1d` (the guard stopped them because `/mnt/data` vanished), then `findmnt /mnt/data`, `dmesg \| grep -iE 'usb\|sda'`. Recovery is manual: once the disk is back and the canary is readable, `cd servarr && docker compose up -d`. This is a write: tell the user first, and check Plex is idle. |
| Deploy postponed repeatedly | someone is streaming; `scripts/plex-busy.sh` output. Wait. Never force. |
| Deploy failed at "Connect to host" | usually a transient tailnet lookup race; re-run with `gh workflow run deploy.yml` and close the auto-opened issue |
| arr apps unreachable | they share `gluetun`'s network: `docker logs gluetun --tail 50` (VPN down takes all of them down) |
| A Kuma monitor is red | Run its check by hand from inside Kuma, for example `docker exec uptime-kuma curl -s http://gluetun:8989/ping`. The per-service URLs are in `docs/HOST.md`. Host-network services go through `host.docker.internal`. |
| Disk health | `sudo smartctl` needs sudo, so ask the user to run `! ssh nathan@192.168.8.10 sudo smartctl -a /dev/disk/by-id/usb-174c_USB_3.1_Storage_0000000000B0-0:0 -d sat` and paste the output |
| Host drift | `bash ~/servarr/scripts/host-drift.sh` (the same check the weekly Scheduled checks workflow runs) |

## Scheduled automation that already watches the host

- `Scheduled checks` workflow (Sundays 19:00 UTC): Terraform drift plan, host drift, secrets expiry (it reads
  `docs/SECRETS.md`). Each opens an issue on a problem.
- `Review replies` sweep (every 5 minutes): keeps the PR gate status fresh.
- Hourly `Deploy`: converges the host to `main`.
- Uptime Kuma checks every service directly (health endpoints, no Docker access) plus the public endpoints, and alerts via Pushbullet.
