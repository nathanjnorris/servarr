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
useradd recyclarr -u 13010

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
usermod -a -G servarr recyclarr

# Make directories
mkdir -p /mnt/data/{torrents,media}/{tv,movies,4ktv,4kmovies}
mkdir -p config/{plex,overseerr,sonarr,4ksonarr,radarr,4kradarr,bazarr,4kbazarr,prowlarr,qbittorrent,maintainerr,tautulli,wizarr,recyclarr,gluetun}-config
# mkdir -p scripts/{sonarr,4ksonarr,radarr,4kradarr}/{custom-services,custom-cont-init}

# Set permissions
chmod -R 775 /mnt/data
chown -R nathan:servarr /mnt/data
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
chown -R tautulli:servarr config/tautulli-config
chown -R recyclarr:servarr config/recyclarr-config