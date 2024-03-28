#!/bin/bash
#

# Make users and groups
sudo useradd plex -u 13001
sudo useradd overseerr -u 13002
sudo useradd sonarr -u 13003
sudo useradd radarr -u 13004
sudo useradd bazarr -u 13005
sudo useradd prowlarr -u 13006
sudo useradd qbittorrent -u 13007
sudo useradd recyclarr -u 13008
sudo useradd tautulli -u 13009
sudo useradd wizarr -u 13010

# Make group
sudo groupadd servarr -g 13000

# Add users to group
sudo usermod -a -G servarr nathan
sudo usermod -a -G servarr plex
sudo usermod -a -G servarr overseerr
sudo usermod -a -G servarr sonarr
sudo usermod -a -G servarr radarr
sudo usermod -a -G servarr bazarr
sudo usermod -a -G servarr prowlarr
sudo usermod -a -G servarr qbittorrent
sudo usermod -a -G servarr recyclarr
sudo usermod -a -G servarr tautulli
sudo usermod -a -G servarr wizarr

# Make directories
sudo mkdir -p /mnt/data/{torrents,media}/{tv,movies}
sudo mkdir -p config/{plex,overseerr,sonarr,radarr,bazarr,prowlarr,qbittorrent,recyclarr,tautulli,wizarr}-config

# Set permissions
sudo chmod -R 775 /mnt/data
sudo chown -R nathan:servarr /mnt/data
sudo chown -R plex:servarr config/plex-config
sudo chown -R overseerr:servarr config/overseerr-config
sudo chown -R sonarr:servarr config/sonarr-config
sudo chown -R radarr:servarr config/radarr-config
sudo chown -R bazarr:servarr config/bazarr-config
sudo chown -R prowlarr:servarr config/prowlarr-config
sudo chown -R qbittorrent:servarr config/qbittorrent-config
sudo chown -R recyclarr:servarr config/recyclarr-config