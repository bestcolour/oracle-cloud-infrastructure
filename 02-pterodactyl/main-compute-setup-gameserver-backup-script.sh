#!/bin/bash

# Exit on error
set -e

echo "Starting Pterodactyl backup sequence..."

# 1. Create a safe database dump
# The password is provided via the environment setup in your docker-compose file
echo "Dumping MariaDB database..."
cd /var/www/pterodactyl
# Safely extract the plaintext password directly from the docker-compose file on the host
DB_PASSWORD=$(grep 'MYSQL_PASSWORD:' /var/www/pterodactyl/docker-compose.yml | sed -e 's/.*MYSQL_PASSWORD: //' -e 's/"//g' -e "s/'//g")

# Run the dump using the host-extracted password variable
sudo docker compose exec -T database mariadb-dump -u pterodactyl -p"$DB_PASSWORD" panel > /srv/pterodactyl/panel_db_backup.sql

# 2. Execute Rclone Sync via Docker
# We mount the host root '/' to '/hostfs' in read-only mode so rclone can access all necessary paths.
echo "Syncing files to cloud storage..."


# =============== Backup Logic ===============
# The name 'pterodactyl_cloud_backup' should be the same as the name of the remote you configured when you ran:
# sudo docker run -it --rm --volume /etc/rclone:/config/rclone --user $(id -u):$(id -g) rclone/rclone config

# This docker run backs up the pterodactyl panel data
sudo docker run --rm \
  --volume /etc/rclone:/config/rclone \
  --volume /:/hostfs:ro \
  rclone/rclone sync /hostfs/srv/pterodactyl pterodactyl_cloud_backup:/pterodactyl_backups/panel_data --progress

# This docker run backs up the pterodactyl wings data
sudo docker run --rm \
  --volume /etc/rclone:/config/rclone \
  --volume /:/hostfs:ro \
  rclone/rclone sync /hostfs/etc/pterodactyl pterodactyl_cloud_backup:/pterodactyl_backups/wings_config --progress

# This docker run backs up the pterodactyl wings game server data
# /var/lib/pterodactyl contains the Wings game server volumes and local backup archives
sudo docker run --rm \
  --volume /etc/rclone:/config/rclone \
  --volume /:/hostfs:ro \
  rclone/rclone sync /hostfs/var/lib/pterodactyl pterodactyl_cloud_backup:/pterodactyl_backups/game_servers --progress

echo "Backup sequence completed successfully."