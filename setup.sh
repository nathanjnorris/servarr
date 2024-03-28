#!/bin/bash
# 

# Make users and groups
useradd plex -u 13001
useradd overseerr -u 13002
useradd sonarr -u 13003
useradd radarr -u 13004
useradd bazarr -u 13005
useradd prowlarr -u 13006
useradd qbittorrent -u 13007
useradd recyclarr -u 13008
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
usermod -a -G servarr recyclarr
usermod -a -G servarr tautulli
usermod -a -G servarr wizarr

# Make directories
mkdir -p /mnt/data/{torrents,media}/{tv,movies}
mkdir -p config/{plex,overseerr,sonarr,radarr,bazarr,prowlarr,qbittorrent,recyclarr,tautulli,wizarr}-config
    
# Set permissions
chmod -R 775 /mnt/data
chown -R nathan:servarr /mnt/data
chown -R plex:servarr config/plex-config
chown -R overseerr:servarr config/overseerr-config
chown -R sonarr:servarr config/sonarr-config
chown -R radarr:servarr config/radarr-config
chown -R bazarr:servarr config/bazarr-config
chown -R prowlarr:servarr config/prowlarr-config
chown -R qbittorrent:servarr config/qbittorrent-config
chown -R recyclarr:servarr config/recyclarr-config
