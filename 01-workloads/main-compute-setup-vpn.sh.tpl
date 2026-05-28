#!/bin/bash
# Exit immediately if any command returns a non-zero status
set -e
HEADSCALE_FQDN="${your_headscale_fqdn}"
HEADSCALE_VERSION="${your_headscale_version}"
BASE_DOMAIN="${your_base_domain}"
PROXY_IP="${reverse_proxy_private_ip}"  # <-- Injected via Terraform
PROXY_PORT="${forward_proxy_port}"

# --- CRITICAL ENVIRONMENT FOR NON-INTERACTIVITY ---
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Route all system downloads through the reverse proxy's tinyproxy instance
export http_proxy="http://$PROXY_IP:$PROXY_PORT"
export https_proxy="http://$PROXY_IP:$PROXY_PORT"
export ftp_proxy="http://$PROXY_IP:$PROXY_PORT"

# Reusable robust Apt Lock Waiter Function
wait_for_apt() {
    echo "Checking package manager locks..."
    while fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 || pgrep -f "apt" >/dev/null 2>&1 || pgrep -f "dpkg" >/dev/null 2>&1;
    do
        echo "The package manager is currently locked by another process. Waiting 10 seconds..."
        sleep 10
    done
    echo "Package manager is free."
}

# --- 0. PURGE NEEDRESTART & UPDATE ---
wait_for_apt
sudo apt-get purge -y needrestart || true
wait_for_apt
sudo apt-get update -y && sudo apt-get install -y curl jq iptables-persistent

# --- 1. DOWNLOAD & INSTALL HEADSCALE ---
echo "Fetching latest Headscale release..."
ARCH="arm64" # Using ARM64 because your shape is VM.Standard.A1.Flex

echo "Downloading Headscale v$HEADSCALE_VERSION for $ARCH..."
curl -L -o /usr/local/bin/headscale "https://github.com/juanfont/headscale/releases/download/v$HEADSCALE_VERSION/headscale_""$HEADSCALE_VERSION""_linux_$ARCH"
chmod +x /usr/local/bin/headscale

# --- 2. CREATE SYSTEM USER AND DIRECTORIES ---
sudo useradd --system --create-home --home-dir /var/lib/headscale --shell /bin/nologin headscale || true
sudo mkdir -p /etc/headscale /var/run/headscale
sudo touch /var/lib/headscale/db.sqlite

# --- 3. CREATE HEADSCALE CONFIGURATION ---
# Headscale expects a configuration file at /etc/headscale/config.yaml
cat <<EOF | sudo tee /etc/headscale/config.yaml
---
server_url: https://$HEADSCALE_FQDN
listen_addr: 0.0.0.0:8080
metrics_listen_addr: 127.0.0.1:9090

db_type: sqlite3
db_path: /var/lib/headscale/db.sqlite

tls_cert_path: ""
tls_key_path: ""

log:
  level: info
  format: text

acl_policy_path: ""
dns_config:
  magic_dns: true
  base_domain: $BASE_DOMAIN
  nameservers:
    - 1.1.1.1
EOF

# Ensure appropriate permissions for the daemon user
sudo chown -R headscale:headscale /etc/headscale /var/lib/headscale /var/run/headscale

# --- 4. CREATE SYSTEMD SERVICE ---
cat <<EOF | sudo tee /etc/systemd/system/headscale.service
[Unit]
Description=headscale controller
After=syslog.target network.target

[Service]
Type=simple
User=headscale
WorkingDirectory=/var/lib/headscale
ExecStart=/usr/local/bin/headscale serve
Restart=always
RestartSec=5

# Optional security hardening
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/headscale /var/run/headscale
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# Reload and spin up Headscale
sudo systemctl daemon-reload
sudo systemctl enable headscale
sudo systemctl start headscale

# --- 5. OS-LEVEL FIREWALL CONFIGURATION (IPTABLES) ---
echo "Opening local OS port 8080 for Nginx Reverse Proxy traffic..."
# Insert rule at line 5 (ahead of Ubuntu's default REJECT rules on OCI)
sudo iptables -I INPUT 5 -m state --state NEW -p tcp --dport 8080 -j ACCEPT
sudo netfilter-persistent save

echo "Headscale deployment completed successfully!"