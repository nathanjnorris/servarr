#!/bin/bash
#

# Make users
useradd plex -u 13001
useradd overseerr -u 13002
useradd sonarr -u 13003
useradd radarr -u 13004
useradd bazarr -u 13005
useradd prowlarr -u 13006
useradd qbittorrent -u 13007
useradd maintainerr -u 13008
useradd tautulli -u 13009
useradd wizarr -u 13010

# Make group
groupadd servarr -g 13000

# Add users to group
usermod -a -G servarr nathan
usermod -a -G servarr plex
usermod -a -G servarr overseerr
usermod -a -G servarr sonarr
usermod -a -G servarr radarr
usermod -a -G servarr bazarr
usermod -a -G servarr prowlarr
usermod -a -G servarr qbittorrent
usermod -a -G servarr maintainerr
usermod -a -G servarr tautulli
usermod -a -G servarr wizarr

# Make directories
mkdir -p /mnt/data/{torrents,media}/{tv,movies,4ktv,4kmovies}
mkdir -p /mnt/data/{recordings,optimised}/{tv,movies}
mkdir -p /var/tmp/plex
mkdir -p config/{plex,overseerr,sonarr,4ksonarr,radarr,4kradarr,bazarr,4kbazarr,prowlarr,qbittorrent,maintainerr,4kmaintainerr,tautulli,wizarr,gluetun,tailscale}-config
mkdir -p /mnt/kopia
mkdir -p /home/nathan/kopia/{config,cache,logs}
mkdir -p /home/nathan/uptime-kuma/data

# Set permissions
chmod -R 775 /mnt/data
chown -R nathan:servarr /mnt/data
chown -R nathan:servarr /mnt/kopia
chown -R nathan:servarr /home/nathan/kopia
chown -R nathan:servarr /home/nathan/uptime-kuma
chown -R plex:servarr /mnt/data/recordings
chown -R plex:servarr /mnt/data/optimised
chown -R plex:servarr /var/tmp/plex
chown -R plex:servarr config/plex-config
chown -R overseerr:servarr config/overseerr-config
chown -R sonarr:servarr config/sonarr-config
chown -R sonarr:servarr config/4ksonarr-config
chown -R radarr:servarr config/radarr-config
chown -R radarr:servarr config/4kradarr-config
chown -R bazarr:servarr config/bazarr-config
chown -R bazarr:servarr config/4kbazarr-config
chown -R prowlarr:servarr config/prowlarr-config
chown -R qbittorrent:servarr config/qbittorrent-config
chown -R maintainerr:servarr config/maintainerr-config
chown -R maintainerr:servarr config/4kmaintainerr-config
chown -R tautulli:servarr config/tautulli-config
chown -R wizarr:servarr config/wizarr-config

## Tailscale exit node
# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
# Persist the changes
sysctl -p /etc/sysctl.d/99-tailscale.conf

# Install macvlan setup service
cp macvlan.sh /etc/macvlan.sh
chmod +x /etc/macvlan.sh
cp macvlan.service /etc/systemd/system/macvlan.service
systemctl daemon-reload
systemctl enable macvlan.service

# Run it now for immediate setup
systemctl start macvlan.service

# UDP throughput improvements using transport layer offloads
printf '#!/bin/sh\n\nethtool -K %s rx-udp-gro-forwarding on rx-gro-list off \n' "$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")" | tee /etc/networkd-dispatcher/routable.d/50-tailscale
chmod 755 /etc/networkd-dispatcher/routable.d/50-tailscale

/etc/networkd-dispatcher/routable.d/50-tailscale || echo 'An error occurred.'