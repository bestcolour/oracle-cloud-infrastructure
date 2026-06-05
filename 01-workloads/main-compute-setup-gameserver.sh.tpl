#!/bin/bash
# Exit immediately if any command returns a non-zero status
set -e

# --- SECURITY CONFIGURATION VARIABLES ---
# Specify only the essential ports required for OS administration/monitoring
# (e.g., "22" for SSH if not already open by default, or your management ports)
SECURE_OPEN_TCP_PORTS="${gameserver_tcp_ports_to_open}" 
SECURE_OPEN_UDP_PORTS="${gameserver_udp_ports_to_open}"  # e.g., "25565 19132"
AUTO_REBOOT="true"
REBOOT_TIME="03:00"
PANEL_DB_PASSWORD="${gameserver_panel_db_password}"
PANEL_APP_KEY="${gameserver_panel_app_key}"

# --- CRITICAL ENVIRONMENT FOR NON-INTERACTIVITY ---
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# --- Duck DNS ---
DUCKDNS_DOMAIN_NAME="${gameserver_duckdns_domain_name}"
DUCKDNS_TOKEN="${duck_dns_token}"

# Reusable robust Apt Lock Waiter Function
wait_for_apt() {
    echo "Checking package manager locks..."
    while fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 || pgrep -f "apt" >/dev/null 2>&1 || pgrep -f "dpkg" >/dev/null 2>&1; do
        echo "The package manager is currently locked by another process. Waiting 10 seconds..."
        sleep 10
    done
    echo "Package manager is free."
}

# --- 1. PURGE NEEDRESTART ---
# Prevents interactive prompts from interrupting automated cloud-init deployments
wait_for_apt
echo "Removing needrestart package to ensure uninterrupted script execution..."
sudo apt-get purge -y needrestart || true

# --- 2. SYSTEM UPDATE ---
wait_for_apt
echo "Starting base system update..."
sudo apt-get update -y && sudo apt-get upgrade -y

# --- 2.5 INSTALL PACKAGES ---
echo "Installing useful packages"
sudo apt-get install -y dnsutils curl nano

# --- 3. INSTALL SECURITY UTILITIES ---
wait_for_apt
echo "Installing automated patching, brute-force protection, and firewall persistence..."
sudo apt-get install -y unattended-upgrades fail2ban iptables-persistent

# --- 4. CONFIGURE AUTOMATIC SECURITY PATCHING (UNATTENDED UPGRADES) ---
echo "Enabling unattended security updates..."
sudo debconf-set-selections <<< "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true"
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

if [ "$AUTO_REBOOT" = "true" ]; then
    echo "Configuring automated maintenance reboots for kernel patches at $REBOOT_TIME..."
    sudo sed -i "s|//Unattended-Upgrade::Automatic-Reboot \"false\";|Unattended-Upgrade::Automatic-Reboot \"true\";|" /etc/apt/apt.conf.d/50unattended-upgrades
    sudo sed -i "s|//Unattended-Upgrade::Automatic-Reboot-Time \"02:00\";|Unattended-Upgrade::Automatic-Reboot-Time \"$REBOOT_TIME\";|" /etc/apt/apt.conf.d/50unattended-upgrades
fi

# --- 5. ORACLE-SPECIFIC STATEFUL FIREWALL HARDENING ---
echo "Injecting explicit TCP rules into OCI iptables chain..."
for PORT in $SECURE_OPEN_TCP_PORTS; do
    echo "Opening required port: $PORT"
    # OCI Ubuntu images typically feature a catch-all REJECT rule on line 5.
    # Injecting at position 5 inserts this rule cleanly right BEFORE the rejection block.
    sudo iptables -I INPUT 5 -m state --state NEW -p tcp --dport "$PORT" -j ACCEPT
done

echo "Injecting explicit UDP rules into OCI iptables chain..."
for PORT in $SECURE_OPEN_UDP_PORTS; do
    echo "Opening required UDP port: $PORT"
    # Injecting at position 5 inserts this rule cleanly right BEFORE the OCI rejection block.
    sudo iptables -I INPUT 5 -m state --state NEW -p udp --dport "$PORT" -j ACCEPT
done

# Save rules so they persist across system restarts
sudo netfilter-persistent save

# --- 6. SSH INFRASTRUCTURE HARDENING ---
echo "Disabling password-based authentication..."
# Eliminates standard brute-force threats by requiring cryptographic SSH keys
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

echo "Restarting SSH daemon to apply changes..."
sudo systemctl restart ssh

echo "----------------------------------------------------"
echo "Security Hardening Complete!"
echo "----------------------------------------------------"

# --- 7. Docker Installation ---
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
systemctl enable docker
sudo systemctl enable --now docker

# --- 8. Pteradactyl Panel Installation ---
echo "Deploying Pterodactyl Panel using Docker Compose..."

# Create directory structure for Pterodactyl
sudo mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl

echo "Cleaning up existing database data to ensure fresh initialization..."
sudo rm -rf /srv/pterodactyl/db/*

# Create a MariaDB client configuration override to disable mandatory TLS
mkdir -p /srv/pterodactyl
cat << 'EOF' > /srv/pterodactyl/skip-ssl.cnf
[client]
skip-ssl = true
EOF

# Generate the docker-compose.yml file natively supporting ARM64 architectures
sudo tee docker-compose.yml > /dev/null <<EOF

networks:
  pterodactyl_nw:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

services:
  database:
    image: mariadb:10.11
    restart: always
    volumes:
      - /srv/pterodactyl/db:/var/lib/mysql
      # Mount the certs
    environment:
      MYSQL_ROOT_PASSWORD: "$PANEL_DB_PASSWORD"
      # Point MariaDB to the certs
      MYSQL_DATABASE: "panel"
      MYSQL_USER: "pterodactyl"
      MYSQL_PASSWORD: "$PANEL_DB_PASSWORD"
      # Append these flags to the command to enforce SSL
      command: --innodb-file-per-table=1 --lower-case-table-names=1
    networks:
      - pterodactyl_nw

  cache:
    image: redis:7-alpine
    restart: always
    networks:
      - pterodactyl_nw

  panel:
    image: ghcr.io/pterodactyl/panel:latest
    restart: always
    # ports:
      # - "8080:80"
    links:
      - database
      - cache
    volumes:
      - /srv/pterodactyl/nginx/:/etc/nginx/http.d/
      - /srv/pterodactyl/var/:/var/log/panel/logs
      - /srv/pterodactyl/skip-ssl.cnf:/etc/my.cnf.d/skip-ssl.cnf:ro
    environment:
      APP_ENV: "production"
      APP_ENVIRONMENT_ONLY: "false"
      APP_URL: "https://$DUCKDNS_DOMAIN_NAME.duckdns.org"
      APP_KEY: "$PANEL_APP_KEY"
      APP_TIMEZONE: "UTC"
      DB_HOST: "database"
      DB_PORT: 3306
      DB_DATABASE: "panel"
      DB_USERNAME: "pterodactyl"
      DB_PASSWORD: "$PANEL_DB_PASSWORD"
      DB_SSLMODE: "DISABLED" # Disables SSL inside the Laravel framework wrapper
      CACHE_DRIVER: "redis"
      SESSION_DRIVER: "redis"
      QUEUE_CONNECTION: "redis"
      REDIS_HOST: "cache"
    networks:
      - pterodactyl_nw
    depends_on:
      - database
      - cache

  # Reverse Proxy to handle SSL automatically using Caddy (ARM64 Native)
  caddy:
    image: caddy:2-alpine
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /srv/pterodactyl/caddy_data:/data
      - /srv/pterodactyl/caddy_config:/config
    environment:
      DOMAIN: "$DUCKDNS_DOMAIN_NAME.duckdns.org"
    command: caddy reverse-proxy --from "$DUCKDNS_DOMAIN_NAME.duckdns.org" --to panel:80
    networks:
      - pterodactyl_nw
    depends_on:
      - panel
EOF

# Spin up Pterodactyl infrastructure
sudo docker compose up -d

echo "Waiting for database initialization and running database migrations..."
# Give the database a brief window to start up before seeding tables
sleep 15
sudo docker compose exec -T panel php artisan migrate --seed --force


# --- 9. DuckDNS Public IP Assignment ---
echo "Discovering instance Public IP address..."
PUBLIC_IP=""
IP_ATTEMPTS=0
while [ -z "$PUBLIC_IP" ] && [ $IP_ATTEMPTS -lt 12 ]; do
    # Try Oracle Metadata endpoint first
    PUBLIC_IP=$(curl -s -H "Authorization: Bearer Oracle" http://192.168.168.168/opc/v2/instance/publicIp 2>/dev/null || echo "")
    
    # Fallback to external resolver if metadata endpoint is blank
    if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "null" ]; then
        PUBLIC_IP=$(curl -s https://ifconfig.me || echo "")
    fi

    if [ -z "$PUBLIC_IP" ]; then
        echo "Public IP not resolved yet by OCI network fabric. Retrying in 10 seconds (Attempt $((IP_ATTEMPTS+1))/12)..."
        sleep 10
        IP_ATTEMPTS=$((IP_ATTEMPTS + 1))
    fi
done

# If we still don't have an IP after 2 minutes, fail gracefully instead of crashing blindly
if [ -z "$PUBLIC_IP" ]; then
    echo "ERROR: Network timed out before a valid Public IP could be detected. Aborting setup."
    exit 1
fi

echo "Successfully detected Public IP of this instance: $PUBLIC_IP"

echo "Updating DuckDNS..."
curl -s "https://www.duckdns.org/update?domains=$DUCKDNS_DOMAIN_NAME&token=$DUCKDNS_TOKEN&ip=$PUBLIC_IP" || echo "DuckDNS API warning triggered."

# Verification Logic: Check if public IP is correctly assigned to duck dns domain name
echo "Verifying DNS propagation..."
VERIFY_ATTEMPTS=0
RESOLVED_IP=""

while [ $VERIFY_ATTEMPTS -lt 6 ]; do
    # Use Google's DNS directly to bypass local caching issues
    RESOLVED_IP=$(dig +short @"8.8.8.8" "$DUCKDNS_DOMAIN_NAME.duckdns.org" | tail -n1)
    
    if [ "$RESOLVED_IP" = "$PUBLIC_IP" ]; then
        echo "SUCCESS: $DUCKDNS_DOMAIN_NAME.duckdns.org correctly points to $PUBLIC_IP"
        break
    fi
    
    echo "DNS not matching yet (Resolved: '$RESOLVED_IP', Expected: '$PUBLIC_IP'). Retrying in 15 seconds..."
    sleep 15
    VERIFY_ATTEMPTS=$((VERIFY_ATTEMPTS + 1))
done

if [ "$RESOLVED_IP" != "$PUBLIC_IP" ]; then
    echo "WARNING: DNS propagation is taking longer than expected. SSL generation via Caddy may delay until DuckDNS refreshes."
fi

# =====================================================================
# --- 10. PTERODACTYL WINGS INSTALLATION ---
# =====================================================================
echo "Staging Pterodactyl Wings environment..."

# Create core configuration and container data directories
sudo mkdir -p /etc/pterodactyl /var/lib/pterodactyl

# Download the compiled Wings binary matching your ARM64 architecture
echo "Downloading ARM64 Wings binary..."
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_arm64"
sudo chmod u+x /usr/local/bin/wings

# Construct the Systemd Service descriptor
echo "Creating systemd unit configuration for Wings..."
sudo tee /etc/systemd/system/wings.service > /dev/null <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=always
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF


# Reload systemd configuration and enable the service on boot
sudo systemctl daemon-reload
sudo systemctl enable wings

echo "Wings setup staged successfully! Awaiting panel configuration token."

echo "----------------------------------------------------"
echo "Deployment Complete! Access panel at: https://$DUCKDNS_DOMAIN_NAME.duckdns.org"
echo "If you receive the message the website is not secure when browsing to the website, please wait for a few minutes for the website's certificate to propagate the internet."
echo "----------------------------------------------------"