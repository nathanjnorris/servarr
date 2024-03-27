#!/bin/bash
# 

# Mount disk
mount /dev/sda /mnt/data/

# Make users and groups
useradd plex -u 13001
useradd overseerr -u 13002
useradd sonarr -u 13003
useradd radarr -u 13004
useradd bazarr -u 13005
useradd prowlarr -u 13006
useradd qbittorrent -u 13007

# Make group
groupadd servarr -g 13000

# Add users to group
usermod -a -G servarr plex 
usermod -a -G servarr overseerr
usermod -a -G servarr sonarr
usermod -a -G servarr radarr
usermod -a -G servarr bazarr
usermod -a -G servarr prowlarr
usermod -a -G servarr qbittorrent

# Make directories
mkdir -p /mnt/data/{torrents,media}/{tv,movies}
mkdir -p config/{plex,overseerr,sonarr,radarr,bazarr,prowlarr,qbittorrent,tautulli,wizarr}-config
    
# Set permissions
chmod -R 775 /mnt/data/
chown -R nathan:servarr /mnt/data/
chown -R plex:servarr config/plex-config
chown -R overseerr:servarr config/overseerr-config
chown -R sonarr:servarr config/sonarr-config
chown -R radarr:servarr config/radarr-config
chown -R bazarr:servarr config/bazarr-config
chown -R prowlarr:servarr config/prowlarr-config
chown -R qbittorrent:servarr config/qbittorrent-config