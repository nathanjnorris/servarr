# The media host

Everything about the machine this repo deploys to that is **not** expressed in code. Re-check it against the live host
(read-only) before relying on it.

## Facts

| Item | Value |
| --- | --- |
| Address | `192.168.8.10` on the LAN; tailnet name `servarr` (Tailscale SSH, `RunSSH: true`) |
| OS | Ubuntu 24.04 LTS |
| Login | `nathan` (sudo needs a password; the deploy sends `SUDO_PASSWORD` on stdin) |
| Repo checkout | `/home/nathan/servarr` (deploys do a hard checkout of `main`; `.deployed-sha` marks the last good deploy) |
| App config | `/home/nathan/servarr/config/<app>-config` (not in git); Kuma `/home/nathan/uptime-kuma/data`; Kopia `/home/nathan/kopia` |
| Backups taken by hand | `/home/nathan/backups/<date>-<reason>/` |
| Media disk | 8 TB on USB (ASMedia `174c:55aa` bridge) at `/mnt/data` (`media/`, `optimised/`, `torrents/`, `recordings/`); canary file `/mnt/data/.mount-ok` |
| Timers from `setup.sh` | `data-mount-guard.timer` (every minute), `optimised-cleanup.timer` (02:20 daily) |
| Networks | `servarr_default` (bridge); `docker_proxy` (internal, Kuma to docker-proxy only); `macvlan0`; the arr apps share `gluetun`'s network namespace; Home Assistant, Traefik-HA and Matter use host networking |

SSH from the deploy workflow goes over the tailnet as `tag:gha`. The tailnet policy file is **not** managed in this
repo. Because Tailscale SSH authenticates with WireGuard node identity, `ssh-keyscan` on the tailnet address is not a
MITM risk, and pinning an OpenSSH host key would break deploys.

## Host settings that are not in `setup.sh`

These were applied by hand (2026-11-21) and verified live. Re-apply them if the host is rebuilt:

```bash
# /etc/fstab: the USB disk may take minutes to enumerate; never block boot on it
UUID=<data-disk-uuid> /mnt/data ext4 defaults,nofail,x-systemd.device-timeout=300s,errors=remount-ro 0 2
# /etc/default/grub (then update-grub): use usb-storage instead of UAS for the bridge (UAS dropouts)
GRUB_CMDLINE_LINUX_DEFAULT="usb-storage.quirks=174c:55aa:u"
# /etc/smartd.conf, first line: watch the USB drive, short test daily 02:00, long test Saturday 03:00
/dev/disk/by-id/usb-174c_USB_3.1_Storage_0000000000B0-0:0 -d sat -a -s (S/../.././02|L/../../6/03)
```

`setup.sh` (run as root by every deploy) owns:
- users and groups;
- `docker.service.d/10-require-data-mount.conf` (Docker never starts without `/mnt/data`);
- journald limits;
- the root-owned guard copy `/usr/local/sbin/data-mount-guard` and its unit;
- the optimised-cleanup unit.

SMART: `sudo smartctl -a /dev/sda` (the device letter can change; use `/dev/disk/by-id/usb-174c_*` with `-d sat`).
Extended self-tests take about 14 hours, and rebooting interrupts them.

## Application settings that live in app databases, not in git

- **qBittorrent**: `AuthSubnetWhitelist=172.18.0.0/16` (the compose network) in `qBittorrent.conf`. Cloudflare Access is
  the only gate for it. Update this if the compose subnet changes.
- **Sonarr, Radarr (and 4K), Prowlarr**: `*__AUTH__METHOD=External` in compose; reached only through Cloudflare Access.
  The "Allowed Hosts is not configured" health warning is cosmetic. This is an accepted risk (see `TECH_DEBT.md`).
- **Pushbullet token**: stored inside Sonarr, 4K Sonarr, Radarr, 4K Radarr, Seerr, Maintainerr and Uptime Kuma.
  Rotate it in each of them.
- **Plex optimise jobs** (Plex DB, `/playlists/1/items`): library-wide jobs for the 4K libraries write to locationID
  18 (Movies) and 23 (TV). Removing `/data/optimised` from those libraries breaks the jobs. Change them only through the
  Plex API, never the DB. `scripts/optimised-cleanup.py` removes orphaned optimised copies nightly.
- **Plex "Empty trash automatically after every scan"**: OFF on purpose (see the incident below).
- **Radarr/Sonarr "Unmonitor Deleted"**: left ON on purpose. Turning it off would re-download everything after a disk
  dropout. The mount guard is the real protection.
- **Maintainerr rules**: live in Maintainerr's DB. Never edit them without the owner's approval.
- **Uptime Kuma**: monitors live in its SQLite DB. Read-only inspection only; the owner edits monitors in the UI. Its
  Docker host is type TCP `http://docker-proxy:2375`. The status page `status.nathanjn.com` is public by design; the
  dashboard needs the owner's login and MFA.
- **Kopia**: the repository password is also the web UI password (`KOPIA_PASSWORD`). Rotating it means re-keying the
  repository. Do not rotate it casually.

## Incident 2026-11-15: data disk dropped off USB

The USB bridge disconnected, 10 seconds after the NIC link flapped (probably a power or cable event; SMART was clean).
Containers kept running against a dead mount for 5.5 days, and the apps then made the damage permanent:
- Plex's empty-trash setting deleted about two thirds of the library entries.
- Radarr unmonitored 42 movies.

What changed afterwards:
- Docker requires the mount at boot.
- The fstab timeout is now 300 s.
- UAS is disabled for the bridge.
- smartd watches the drive.
- Plex auto-empty-trash is off.
- `data-mount-guard` stops every container that bind-mounts `/mnt/data` within a minute if the canary file becomes
  unreadable.
