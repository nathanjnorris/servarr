#!/bin/bash

# Make users and groups
useradd plex -u 13001
useradd overseerr -u 13002

useradd sonarr -u 13003
useradd radarr -u 13004
useradd bazarr -u 13005
useradd prowlarr -u 13006
useradd qbittorrent -u 13007

groupadd servarr -g 13000

usermod -a -G servarr plex
usermod -a -G servarr overseerr
usermod -a -G servarr sonarr
usermod -a -G servarr radarr
usermod -a -G servarr bazarr
usermod -a -G servarr prowlarr
usermod -a -G servarr qbittorrent

# Make directories

mkdir -pv /mnt/data/{torrents,media}/{tv,movies}
    
# Set permissions
chmod -R 775 /mnt/data/
chown -R $(id -u):servarr /mnt/data/

echo "UID=$(id -u)" >> .env