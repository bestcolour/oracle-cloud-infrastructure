#!/bin/bash
set -e
# https://youtu.be/9DnCIpbn-8o?si=cu65TpT1mV5oVdEO
#######################################################################
# ORACLE CLOUD UBUNTU INTEGRATED SECURITY & REVERSE PROXY SETUP SCRIPT
# This script automates: Unattended Upgrades, Fail2Ban, Firewall,
# and an Nginx Reverse Proxy configuration for Headscale & Side Projects.
#######################################################################

# --- VARIABLES ---
# Security Configuration
OPEN_TCP_PORTS="${your_tcp_ports}" # eg. 80 443
AUTO_REBOOT="true"
REBOOT_TIME="03:00"

# --- Automate DuckDNS Update ---
DUCKDNS_TOKEN="${your_duckdns_token}" # (Replace 'your-duckdns-token' and 'your-domain')
DUCKDNS_DOMAIN="${your_duckdns_domainname}" # just the name, not the .duckdns.org part
MAX_RETRIES=20

# --- DOMAIN & BACKEND CONFIGURATION ---
# Base domain (e.g., example.com)
BASE_DOMAIN="${your_base_domain}" 

# Headscale Configuration
HEADSCALE_SUBDOMAIN="headscale.$BASE_DOMAIN"
HEADSCALE_BACKEND="${headscale_private_ip_n_port}" # Update to your actual private Headscale IP and port eg. "10.0.1.10:8080"

# Side Project Configuration
PROJECTS_SUBDOMAIN="projects.$BASE_DOMAIN"
PROJECTS_BACKEND="${projects_private_ip_n_port}"  # Update to your actual private side-project IP and port

# Prevent interactive prompts during apt installations
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a  # Tells needrestart to automatically restart services without asking
# Force dpkg/apt to always use default options and never prompt
echo 'force-confold' | sudo tee /etc/dpkg/dpkg.cfg.d/force-confold

# --- 0. WAIT FOR AP-DAILY / DPKG LOCKS TO RELEASE ---
echo "Waiting for background system upgrade processes to finish..."
while fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
    echo "Apt lock is held by another process. Waiting 5 seconds..."
    sleep 5
done

# --- 1. SYSTEM UPDATE ---
echo "Starting system update..."
sudo apt-get update -y && sudo apt-get upgrade -y

# --- 2. INSTALL PACKAGES ---
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
for PORT in $OPEN_TCP_PORTS; do
    echo "Opening TCP port: $PORT"
    sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport "$PORT" -j ACCEPT
done

sudo netfilter-persistent save

# --- 5. SSH HARDENING ---
echo "Hardening SSH configuration..."
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# --- 6. CREATE HEADSCALE & SIDE PROJECTS REVERSE PROXY CONFIGURATION ---
echo "Configuring Nginx split routing for Headscale and Side Projects..."

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Create the deployment config
cat <<EOF | sudo tee /etc/nginx/sites-available/reverse_proxy
# 1. Headscale Control Server Configuration
server {
    listen 80;
    server_name $HEADSCALE_SUBDOMAIN;

    # Increase maximum upload size for Headscale (useful for pre-auth keys / node keys)
    client_max_body_size 0;

    location / {
        proxy_pass http://$HEADSCALE_BACKEND;
        
        # Essential Proxy Headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # CRITICAL FOR HEADSCALE: WebSockets & Long-Polling Keep-Alive
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Extend timeouts so Headscale control protocol streams don't unexpectedly drop
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

# --- 6.5 AUTOMATED SSL/TLS (HTTPS) SETUP WITH CERTBOT ---
echo "Starting automated SSL/TLS setup via Certbot..."

# 1. Install Certbot and its Nginx plugin non-interactively
sudo apt-get install -y certbot python3-certbot-nginx

# 2. Get the instance's current public IP (Oracle metadata endpoint)
PUBLIC_IP=$(curl -s -H "Authorization: Bearer Oracle" http://192.168.168.168/opc/v2/instance/publicIp 2>/dev/null)

# Fallback method if the metadata endpoint isn't fully available yet
if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP=$(curl -s https://ifconfig.me)
fi

echo "Detected Public IP of this instance: $PUBLIC_IP"



echo "Updating DuckDNS..."
curl -s "https://www.duckdns.org/update?domains=$DUCKDNS_DOMAIN&token=$DUCKDNS_TOKEN&ip=$PUBLIC_IP"

# 3. DNS Waiter Loop with a Max Timeout (e.g., 20 attempts = 5 minutes)
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
        echo "ERROR: DNS failed to propagate after 5 minutes. Skipping Certbot setup to prevent infinite hang."
        exit 1 # Or handle gracefully without exiting so the rest of the script finishes
    fi
done

# 4. Request the SSL Certificates
# Replace 'admin@$BASE_DOMAIN' with your actual administrative email if desired
echo "Requesting Let's Encrypt certificates for $HEADSCALE_SUBDOMAIN and $PROJECTS_SUBDOMAIN..."
sudo certbot --nginx \
  --non-interactive \
  --agree-tos \
  --email "admin@$BASE_DOMAIN" \
  -d "$HEADSCALE_SUBDOMAIN" \
  -d "$PROJECTS_SUBDOMAIN" \
  --redirect

# 5. Verify configuration and reload Nginx to absorb changes
echo "Verifying Nginx configuration after Certbot modification..."
sudo nginx -t
if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    echo "SSL/TLS setup completed and Nginx successfully updated to HTTPS."
else
    echo "Certbot modifications corrupted the Nginx config. Check /etc/nginx/sites-available/reverse_proxy"
    exit 1
fi

# --- 7. VALIDATE AND RESTART NGINX ---
echo "Validating Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    sudo systemctl restart nginx
    echo "Nginx Reverse Proxy setup completed successfully."
else
    echo "Nginx configuration test failed. Please check the logs."
    exit 1
fi

# --- 8. FINISH ---
echo "----------------------------------------------------"
echo "Setup Complete!"
echo "Headscale public entrypoint: http://$HEADSCALE_SUBDOMAIN"
echo "Side projects public entrypoint: http://$PROJECTS_SUBDOMAIN"
echo "Note: Ensure your DNS provider points both subdomains to this instance's public IP."
echo "----------------------------------------------------"