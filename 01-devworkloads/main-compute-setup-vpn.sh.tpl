#!/bin/bash
# Exit immediately if any command returns a non-zero status
set -e
HEADSCALE_FQDN="${your_headscale_fqdn}"
HEADSCALE_VERSION="${your_headscale_version}"
HEADSCALE_ARCH_TYPE="${your_headscale_arch_type}" 
BASE_DOMAIN="${your_secure_web_gateway_base_domain}"
SECURE_WEB_GATEWAY_IP="${secure_web_gateway_private_ip}"  # <-- Injected via Terraform
FORWARD_PROXY_PORT="${forward_proxy_port}"
REVERSE_PROXY_PORT_TO_OPEN="${reverse_proxy_port_to_open}" # usually is 8080

# --- CRITICAL ENVIRONMENT FOR NON-INTERACTIVITY ---
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Route all system downloads through the reverse proxy's tinyproxy instance
export http_proxy="http://$SECURE_WEB_GATEWAY_IP:$FORWARD_PROXY_PORT"
export https_proxy="http://$SECURE_WEB_GATEWAY_IP:$FORWARD_PROXY_PORT"
export ftp_proxy="http://$SECURE_WEB_GATEWAY_IP:$FORWARD_PROXY_PORT"
export no_proxy="localhost,127.0.0.1,::1" # <-- ADD THIS

# --- -6. WAIT FOR TINYPROXY & CONFIGURE APT ---
# this section was added to allow the headscale VM to run only after the secure web gateway has finished setting up the forward proxy. The reason why we dont use terraform's "depends on" to do this is because cloud-init setup runs are asynchronous in the context of Terraform provisioning. Terraform will provision the secure web gateway computing instance first but it will not wait for its cloud init script to finish before provisioning and running headscale's computing instance & cloud init script
echo "Waiting for Secure Web Gateway (Tinyproxy) to come online..."
# Loop until we can successfully fetch headers from the Ubuntu archive through the proxy
until curl -x "http://$SECURE_WEB_GATEWAY_IP:$FORWARD_PROXY_PORT" -I "http://archive.ubuntu.com" -m 5 -s -o /dev/null; do
    echo "Tinyproxy at $SECURE_WEB_GATEWAY_IP:$FORWARD_PROXY_PORT is not ready yet. Retrying in 15 seconds..."
    sleep 15
done
echo "Tinyproxy is reachable! Proceeding with setup."

# Force APT to use the proxy (since sudo drops standard environment variables)
echo "Acquire::http::Proxy \"http://$SECURE_WEB_GATEWAY_IP:$FORWARD_PROXY_PORT\";" | sudo tee /etc/apt/apt.conf.d/01proxy
echo "Acquire::https::Proxy \"http://$SECURE_WEB_GATEWAY_IP:$FORWARD_PROXY_PORT\";" | sudo tee -a /etc/apt/apt.conf.d/01proxy

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

# --- -5. PURGE NEEDRESTART & UPDATE ---
wait_for_apt
sudo apt-get purge -y needrestart || true
wait_for_apt
sudo apt-get update -y && sudo apt-get install -y curl jq iptables-persistent nano

# --- -4. SYSTEM UPDATE ---
wait_for_apt
echo "Starting base system update..."
sudo apt-get update -y && sudo apt-get upgrade -y

# --- -3. INSTALL SECURITY UTILITIES ---
wait_for_apt
echo "Installing automated patching, brute-force protection, and firewall persistence..."
sudo apt-get install -y unattended-upgrades fail2ban iptables-persistent

# --- -2. CONFIGURE AUTOMATIC SECURITY PATCHING (UNATTENDED UPGRADES) ---
echo "Enabling unattended security updates..."
sudo debconf-set-selections <<< "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true"
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

if [ "$AUTO_REBOOT" = "true" ]; then
    echo "Configuring automated maintenance reboots for kernel patches at $REBOOT_TIME..."
    sudo sed -i "s|//Unattended-Upgrade::Automatic-Reboot \"false\";|Unattended-Upgrade::Automatic-Reboot \"true\";|" /etc/apt/apt.conf.d/50unattended-upgrades
    sudo sed -i "s|//Unattended-Upgrade::Automatic-Reboot-Time \"02:00\";|Unattended-Upgrade::Automatic-Reboot-Time \"$REBOOT_TIME\";|" /etc/apt/apt.conf.d/50unattended-upgrades
fi

# --- -1. ORACLE-SPECIFIC STATEFUL FIREWALL HARDENING ---
echo "Injecting explicit rules into OCI iptables chain..."
for PORT in $SECURE_OPEN_TCP_PORTS; do
    echo "Opening required port: $PORT"
    # OCI Ubuntu images typically feature a catch-all REJECT rule on line 5.
    # Injecting at position 5 inserts this rule cleanly right BEFORE the rejection block.
    sudo iptables -I INPUT 5 -m state --state NEW -p tcp --dport "$PORT" -j ACCEPT
done

# Save rules so they persist across system restarts
sudo netfilter-persistent save

# --- 0. SSH INFRASTRUCTURE HARDENING ---
echo "Disabling password-based authentication..."
# Eliminates standard brute-force threats by requiring cryptographic SSH keys
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

echo "Restarting SSH daemon to apply changes..."
sudo systemctl restart ssh

echo "----------------------------------------------------"
echo "Security Hardening Complete!"
echo "----------------------------------------------------"

# --- 1. DOWNLOAD & INSTALL HEADSCALE ---
echo "Fetching latest Headscale release..."

echo "Downloading Headscale v$HEADSCALE_VERSION for $HEADSCALE_ARCH_TYPE..."
curl -L -o /usr/local/bin/headscale "https://github.com/juanfont/headscale/releases/download/v$HEADSCALE_VERSION/headscale_""$HEADSCALE_VERSION""_linux_$HEADSCALE_ARCH_TYPE"
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

# Required for the CLI to communicate with the daemon securely
unix_socket: /var/run/headscale/headscale.sock
unix_socket_permission: "0770"

# Required for Headscale 0.28.0+ Noise protocol
noise:
  private_key_path: /var/lib/headscale/noise_private.key

# Required IP allocation ranges for Tailscale clients
prefixes:
  v4: 100.64.0.0/10
  v6: fd7a:115c:a1e0::/48

# Modernized database block
database:
  type: sqlite3
  sqlite:
    path: /var/lib/headscale/db.sqlite

tls_cert_path: ""
tls_key_path: ""

log:
  level: info
  format: text

# Modernized DNS block
dns:
  magic_dns: true
  base_domain: vpn.internal
  nameservers:
    global:
      - 1.1.1.1

derp:
  server:
    enabled: false
  urls:
    - https://controlplane.tailscale.com/derpmap/default
  paths: []
  auto_update_enabled: true
  update_frequency: 24h
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
# --- INJECT PROXY VARIABLES FOR DAEMON INTERNET ROUTING ---
Environment="HTTP_PROXY=http://$SECURE_WEB_GATEWAY_IP:$FORWARD_PROXY_PORT"
Environment="HTTPS_PROXY=http://$SECURE_WEB_GATEWAY_IP:$FORWARD_PROXY_PORT"
Environment="NO_PROXY=localhost,127.0.0.1"
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
echo "Opening local OS port $REVERSE_PROXY_PORT_TO_OPEN for Nginx Reverse Proxy traffic..."
# Insert rule at line 5 (ahead of Ubuntu's default REJECT rules on OCI)
sudo iptables -I INPUT 5 -m state --state NEW -p tcp --dport $REVERSE_PROXY_PORT_TO_OPEN -j ACCEPT
sudo netfilter-persistent save

echo "Headscale deployment completed successfully!"