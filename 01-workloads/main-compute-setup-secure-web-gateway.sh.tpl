#!/bin/bash
# Exit immediately if any command returns a non-zero status
set -e

#######################################################################
# ORACLE CLOUD UBUNTU INTEGRATED SECURITY & REVERSE PROXY SETUP SCRIPT & FORWARD PROXY SETUP
#######################################################################

# --- Reverse Proxy - VARIABLES ---
REVERSE_PROXY_OPEN_TCP_PORTS="${your_reverse_proxy_tcp_ports}" # e.g., "80 443"
AUTO_REBOOT="true"
REBOOT_TIME="03:00"

# --- Reverse Proxy - Automate DuckDNS Update ---
DUCKDNS_TOKEN="${your_duckdns_token}"
DUCKDNS_DOMAIN_NAME="${your_duckdns_domainname}"
MAX_RETRIES=20

# --- Reverse Proxy - DOMAIN & BACKEND CONFIGURATION ---
BASE_DOMAIN="${your_base_domain}" 

# Headscale Subdomain (Routed through HTTP backend rule)
HEADSCALE_SUBDOMAIN="${your_headscale_subdomain_name}.$BASE_DOMAIN"
HEADSCALE_BACKEND="${headscale_private_ip_n_port}" 

# Side Project Subdomain (Routed through HTTPS backend rule)
PROJECTS_SUBDOMAIN="${your_project_1_subdomain_name}.$BASE_DOMAIN"
PROJECTS_BACKEND="${projects_private_ip_n_port}"

# --- Forward Proxy ---
FORWARD_PROXY_PORT="${forward_proxy_port}"
VCN_CIDR_BLOCK="${your_vcn_cidr_block}" #eg. 10.0.0.0/16

# --- CRITICAL ENVIRONMENT FOR NON-INTERACTIVITY ---
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Reusable robust Apt Lock Waiter Function
wait_for_apt() {
    echo "Checking package manager locks..."
    # Loop while any lock file is held or while dpkg/apt processes are actively running
    while fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 || pgrep -f "apt" >/dev/null 2>&1 || pgrep -f "dpkg" >/dev/null 2>&1; do
        echo "The package manager is currently locked by another process. Waiting 10 seconds..."
        sleep 10
    done
    echo "Package manager is free."
}

# --- 0. PURGE NEEDRESTART ---
wait_for_apt
echo "Removing needrestart package to prevent cloud-final execution termination..."
sudo apt-get purge -y needrestart || true

# --- 1. SYSTEM UPDATE ---
wait_for_apt
echo "Starting system update..."
sudo apt-get update -y && sudo apt-get upgrade -y

# --- 2. INSTALL PACKAGES ---
wait_for_apt
echo "Installing required packages (Security & Nginx)..."
sudo apt-get install -y unattended-upgrades fail2ban iptables-persistent nginx dnsutils curl

# Ensure Nginx starts on boot and is currently running
sudo systemctl enable nginx
sudo systemctl start nginx

# --- 3. CONFIGURE UNATTENDED UPGRADES ---
echo "Configuring automatic security updates..."
sudo debconf-set-selections <<< "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true"
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

if [ "$AUTO_REBOOT" = "true" ]; then
    echo "Setting up automatic reboots at $REBOOT_TIME..."
    sudo sed -i "s|//Unattended-Upgrade::Automatic-Reboot \"false\";|Unattended-Upgrade::Automatic-Reboot \"true\";|" /etc/apt/apt.conf.d/50unattended-upgrades
    sudo sed -i "s|//Unattended-Upgrade::Automatic-Reboot-Time \"02:00\";|Unattended-Upgrade::Automatic-Reboot-Time \"$REBOOT_TIME\";|" /etc/apt/apt.conf.d/50unattended-upgrades
fi

# --- 4. CONFIGURE ORACLE FIREWALL (IPTABLES) ---
echo "Configuring iptables for Oracle Cloud..."
for PORT in $REVERSE_PROXY_OPEN_TCP_PORTS; do
    echo "Opening TCP port: $PORT"
    # line 5 is chosen as it will be the REJECT rule line. We want to place our new rules BEFORE the reject rule
    sudo iptables -I INPUT 5 -m state --state NEW -p tcp --dport "$PORT" -j ACCEPT
done

echo "Opening TCP port: $FORWARD_PROXY_PORT for Forward Proxy"
sudo iptables -I INPUT 5 -m state --state NEW -p tcp --dport "$FORWARD_PROXY_PORT" -j ACCEPT

sudo netfilter-persistent save

# --- 5. SSH HARDENING ---
echo "Hardening SSH configuration..."
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# --- 6. CREATE HEADSCALE & SIDE PROJECTS REVERSE PROXY CONFIGURATION ---
echo "Configuring Nginx split routing for Headscale and Side Projects..."

sudo rm -f /etc/nginx/sites-enabled/default

cat <<EOF | sudo tee /etc/nginx/sites-available/reverse_proxy
# 1. Headscale Control Server Configuration
server {
    listen 80;
    server_name $HEADSCALE_SUBDOMAIN;
    client_max_body_size 0;

    location / {
        proxy_pass http://$HEADSCALE_BACKEND;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_connect_timeout 150s;
        proxy_send_timeout 100s;
        proxy_read_timeout 100s;
    }
}

# 2. Side Projects Configuration
server {
    listen 80;
    server_name $PROJECTS_SUBDOMAIN;

    location / {
        proxy_pass http://$PROJECTS_BACKEND;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the configuration
sudo ln -sf /etc/nginx/sites-available/reverse_proxy /etc/nginx/sites-enabled/

# Reload Nginx so it actively serves your subdomains before Certbot triggers
sudo nginx -t
sudo systemctl reload nginx

# --- 6.5 AUTOMATED SSL/TLS (HTTPS) SETUP WITH CERTBOT ---
echo "Starting automated SSL/TLS setup via Certbot..."

wait_for_apt
sudo apt-get install -y certbot python3-certbot-nginx

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
    echo "ERROR: Network timed out before a valid Public IP could be detected. Aborting Certbot setup."
    exit 1
fi

echo "Successfully detected Public IP of this instance: $PUBLIC_IP"

echo "Updating DuckDNS..."
# Appending || true ensures that even if DuckDNS responds slowly, it won't trigger set -e to kill our script
curl -s "https://www.duckdns.org/update?domains=$DUCKDNS_DOMAIN_NAME&token=$DUCKDNS_TOKEN&ip=$PUBLIC_IP" || echo "DuckDNS API warning triggered."

# DNS Waiter Loop
for DOMAIN in "$HEADSCALE_SUBDOMAIN" "$PROJECTS_SUBDOMAIN"; do
    echo "Checking DNS resolution for $DOMAIN..."
    ATTEMPTS=0
    while [ $ATTEMPTS -lt $MAX_RETRIES ]; do
        RESOLVED_IP=$(dig +short "$DOMAIN" | tail -n1)
        if [ "$RESOLVED_IP" = "$PUBLIC_IP" ]; then
            echo "Success: $DOMAIN correctly resolves to $PUBLIC_IP"
            break
        fi
        echo "Waiting for DNS $DOMAIN -> $PUBLIC_IP (Currently: '$RESOLVED_IP'). Retrying in 15 seconds..."
        sleep 15
        ATTEMPTS=$((ATTEMPTS + 1))
    done
    
    if [ $ATTEMPTS -eq $MAX_RETRIES ]; then
        echo "ERROR: DNS failed to propagate after 5 minutes. Stopping execution."
        exit 1
    fi
done

echo "Requesting Let's Encrypt certificates..."
sudo certbot --nginx \
  --non-interactive \
  --agree-tos \
  --email "admin@$BASE_DOMAIN" \
  -d "$HEADSCALE_SUBDOMAIN" \
  -d "$PROJECTS_SUBDOMAIN" \
  --redirect

echo "Verifying and reloading Nginx configuration..."
sudo nginx -t
sudo systemctl reload nginx

# --- 7. FORWARD PROXY CONFIGURATION FOR PRIVATE SUBNET ---
echo "Installing and configuring Tinyproxy as a forward proxy..."
wait_for_apt
sudo apt-get install -y tinyproxy

# Configure Tinyproxy to allow your internal VCN subnet (adjust 10.0.0.0/16 if your VCN CIDR is different)
sudo sed -i "s/^Port $FORWARD_PROXY_PORT/Port $FORWARD_PROXY_PORT/" /etc/tinyproxy/tinyproxy.conf
echo "Allow $VCN_CIDR_BLOCK" | sudo tee -a /etc/tinyproxy/tinyproxy.conf

sudo systemctl restart tinyproxy
sudo systemctl enable tinyproxy

echo "----------------------------------------------------"
echo "Setup Complete!"
echo "----------------------------------------------------"