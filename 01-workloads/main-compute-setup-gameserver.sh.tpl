#!/bin/bash
# Exit immediately if any command returns a non-zero status
set -e

# --- CRITICAL ENVIRONMENT FOR NON-INTERACTIVITY ---
export DEBIAN_FRONTEND=noninteractive

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

# --- 3. INSTALL ANSIBLE UTILITIES ---

echo "Updating repositories and ensuring base prerequisites..."
wait_for_apt
apt-get update -y
apt-get install -y software-properties-common curl git

echo "Adding official Ansible distribution PPA..."
wait_for_apt
apt-add-repository --yes --update ppa:ansible/ansible

echo "Installing Ansible engine automation components..."
wait_for_apt
apt-get install -y ansible

# --- 4. INSTALL DOCKER ---

echo "Installing Docker..."
wait_for_apt
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
systemctl enable docker
sudo systemctl enable --now docker

# --- 5. DuckDNS Public IP Assignment ---
echo "Discovering instance Public IP address..."
PUBLIC_IP=""
IP_ATTEMPTS=0
DUCKDNS_DOMAIN_NAME="${gameserver_duckdns_domain_name}"
DUCKDNS_TOKEN="${duck_dns_token}"

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


# --- 6. CONFIGURATION PATH EXTRACTION TARGETS ---
# Swap this with your actual public repository URL paths where configuration documents reside
GITHUB_RAW_BASE="${gameserver_github_raw_base_url}"

echo "Downloading deployment playbook and Jinja2 templates directly from GitHub version control..."
curl -sSL "$GITHUB_RAW_BASE/"${gameserver_github_repo_playbook_path}"" -o /tmp/playbook.yml
curl -sSL "$GITHUB_RAW_BASE/"${gameserver_github_repo_pterodactyl_docker_compose_path}"" -o /tmp/docker-compose.yml.j2

echo "Injecting secret state and environment mappings into localized Ansible values context file..."
cat <<EOF > /tmp/vars.yml
gameserver_tcp_ports_to_open: "${gameserver_tcp_ports_to_open}"
gameserver_udp_ports_to_open: "${gameserver_udp_ports_to_open}"
auto_reboot: "true"
reboot_time: "03:00"
panel_db_password: "${gameserver_panel_db_password}"
panel_app_key: "${gameserver_panel_app_key}"
duckdns_domain_name: "${gameserver_duckdns_domain_name}"
EOF

echo "Executing localized orchestrator playbook using contextual values profile..."
ansible-playbook /tmp/playbook.yml -e @/tmp/vars.yml

echo "----------------------------------------------------"
echo "Ansible Local Configuration Tasks Succeeded!"
echo "----------------------------------------------------"