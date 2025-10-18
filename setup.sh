#!/bin/bash
#

# Make users (only if they don't exist)
id plex &>/dev/null || useradd plex -u 13001
id overseerr &>/dev/null || useradd overseerr -u 13002
id sonarr &>/dev/null || useradd sonarr -u 13003
id radarr &>/dev/null || useradd radarr -u 13004
id bazarr &>/dev/null || useradd bazarr -u 13005
id prowlarr &>/dev/null || useradd prowlarr -u 13006
id qbittorrent &>/dev/null || useradd qbittorrent -u 13007
id maintainerr &>/dev/null || useradd maintainerr -u 13008
id tautulli &>/dev/null || useradd tautulli -u 13009
id wizarr &>/dev/null || useradd wizarr -u 13010

# Make group (only if it doesn't exist)
getent group servarr &>/dev/null || groupadd servarr -g 13000

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
# Enable IP forwarding in tailscale sysctl.d (only if not already configured)
if ! grep -q "net.ipv4.ip_forward = 1" /etc/sysctl.d/99-tailscale.conf 2>/dev/null; then
    printf 'net.ipv4.ip_forward = 1\nnet.ipv6.conf.default.forwarding = 1\n' | tee /etc/sysctl.d/99-tailscale.conf
    # Persist the changes
    sysctl -p /etc/sysctl.d/99-tailscale.conf
fi

# Enable IP forwarding in UFW sysctl.conf (only if still commented)
if grep -q "^#net/ipv4/ip_forward=1" /etc/ufw/sysctl.conf; then
    sed -i 's/^#net\/ipv4\/ip_forward=1/net\/ipv4\/ip_forward=1/' /etc/ufw/sysctl.conf
fi

if grep -q "^#net/ipv6/conf/default/forwarding=1" /etc/ufw/sysctl.conf; then
    sed -i 's/^#net\/ipv6\/conf\/default\/forwarding=1/net\/ipv6\/conf\/default\/forwarding=1/' /etc/ufw/sysctl.conf
fi

# Update UFW default forward policy (only if needed)
if grep -q 'DEFAULT_FORWARD_POLICY="DROP"' /etc/default/ufw; then
    sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
fi

# Update UFW before.rules to add NAT rules (only if not already present)
if ! grep -q "Forward traffic through enp1s0" /etc/ufw/before.rules; then
    sed -i '/^# Rules that should be run before the ufw command line added rules\. Custom$/,/^#$/{
        /^#$/c\
#\
\
# nat Table rules\
*nat\
:POSTROUTING ACCEPT [0:0]\
\
# Forward traffic through enp1s0.\
-A POSTROUTING -o enp1s0 -j MASQUERADE\
\
# don'\''t delete the '\''COMMIT'\'' line or these nat table rules won'\''t be processed\
COMMIT\

    }' /etc/ufw/before.rules
fi

# Restart UFW to apply all changes
ufw --force disable && ufw --force enable

# Install macvlan setup service (only if not already installed)
if [ ! -f /etc/systemd/system/macvlan.service ]; then
    cp macvlan.sh /etc/macvlan.sh
    chmod +x /etc/macvlan.sh
    cp macvlan.service /etc/systemd/system/macvlan.service
    systemctl daemon-reload
    systemctl enable macvlan.service
fi

# Run it now for immediate setup (safe to run multiple times)
systemctl start macvlan.service

# UDP throughput improvements using transport layer offloads (only if not already configured)
if [ ! -f /etc/networkd-dispatcher/routable.d/50-tailscale ]; then
    printf '#!/bin/sh\n\nethtool -K %s rx-udp-gro-forwarding on rx-gro-list off \n' "$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")" | tee /etc/networkd-dispatcher/routable.d/50-tailscale
    chmod 755 /etc/networkd-dispatcher/routable.d/50-tailscale
    
    # Run it now for immediate setup
    /etc/networkd-dispatcher/routable.d/50-tailscale || echo 'An error occurred.'
fi