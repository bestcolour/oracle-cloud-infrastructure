#!/bin/bash
# Exit immediately if any command returns a non-zero status
set -e 

SECURE_OPEN_TCP_PORTS="${gameserver_tcp_ports_to_open}" 
SECURE_OPEN_UDP_PORTS="${gameserver_udp_ports_to_open}"  # e.g., "25565 19132"
PANEL_DB_PASSWORD="${gameserver_panel_db_password}"
PANEL_APP_KEY="${gameserver_panel_app_key}"

# --- Duck DNS ---
DUCKDNS_DOMAIN_NAME="${gameserver_duckdns_domain_name}"
DUCKDNS_TOKEN="${duck_dns_token}"

# --- CRITICAL ENVIRONMENT FOR NON-INTERACTIVITY ---
export DEBIAN_FRONTEND=noninteractive 
export NEEDRESTART_MODE=a 

# Reusable robust Apt Lock Waiter Function
wait_for_apt() {
    echo "Checking package manager locks..."
    while fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1 || 
          pgrep -f "apt" >/dev/null 2>&1 || pgrep -f "dpkg" >/dev/null 2>&1; [cite: 2]
    do [cite: 3]
        echo "The package manager is currently locked by another process. Waiting 10 seconds..."
        sleep 10
    done [cite: 3]
    echo "Package manager is free."
} 

# --- 1. PURGE NEEDRESTART ---
# Prevents interactive prompts from interrupting automated cloud-init deployments
wait_for_apt 
echo "Removing needrestart package to ensure uninterrupted script execution..."
sudo apt-get purge -y needrestart || true [cite: 4, 5]

# --- 2. UPDATE & INSTALL SOFTWARE PROPERTIES ---
wait_for_apt
sudo apt-get update -y
sudo apt-get install -y software-properties-common curl git

# --- 3. INSTALL ANSIBLE ---
echo "Installing Ansible..."
sudo fallback-to-ppa-if-needed || true # Optional step if on an older Ubuntu version needing the Ansible PPA
wait_for_apt
sudo apt-get install -y ansible

# --- 4. EXECUTE PLAYBOOK ---
echo "Launching local Ansible provisioning..."
# Option A: If cloning from a git repository:
# git clone https://github.com/your-organization/pterodactyl-ansible.git /tmp/ansible
# ansible-playbook /tmp/ansible/site.yml --extra-vars "db_password=${gameserver_panel_db_password} app_key=${gameserver_panel_app_key} ..."

# Option B: If baking the playbook dynamically into a local file via Terraform:
# ansible-playbook /tmp/local-site.yml