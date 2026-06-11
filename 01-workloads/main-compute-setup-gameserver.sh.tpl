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

# --- CONFIGURATION PATH EXTRACTION TARGETS ---
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
duckdns_token: "${duck_dns_token}"
EOF

echo "Executing localized orchestrator playbook using contextual values profile..."
ansible-playbook /tmp/playbook.yml -e @/tmp/vars.yml

echo "----------------------------------------------------"
echo "Ansible Local Configuration Tasks Succeeded!"
echo "----------------------------------------------------"