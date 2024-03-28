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
mkdir -p /mnt/data/{torrents,media}/{tv,movies}
mkdir -p config/{plex,overseerr,sonarr,radarr,bazarr,prowlarr,qbittorrent,maintainerr,tautulli,wizarr}-config
mkdir -p scripts/{sonarr,radarr}-scripts/{custom-services,custom-cont-init}

# Download arr-scripts
wget https://raw.githubusercontent.com/RandomNinjaAtk/arr-scripts/main/sonarr/scripts_init.bash -O /home/nathan/servarr/scripts/sonarr/custom-cont-init/scripts_init.bash
wget https://raw.githubusercontent.com/RandomNinjaAtk/arr-scripts/main/radarr/scripts_init.bash -O /home/nathan/servarr/scripts/radarr/custom-cont-init/scripts_init.bash

# Set permissions
chmod -R 775 /mnt/data
chown -R nathan:servarr /mnt/data
chown -R plex:servarr config/plex-config
chown -R overseerr:servarr config/overseerr-config
chown -R sonarr:servarr config/sonarr-config
chown -R sonarr:servarr scripts/sonarr-scripts
chown -R radarr:servarr config/radarr-config
chown -R radarr:servarr scripts/radarr-scripts
chown -R bazarr:servarr config/bazarr-config
chown -R prowlarr:servarr config/prowlarr-config
chown -R qbittorrent:servarr config/qbittorrent-config
chown -R maintainerr:servarr config/maintainerr-config
chown -R tautulli:servarr config/tautulli-config
chown -R wizarr:servarr config/wizarr-config