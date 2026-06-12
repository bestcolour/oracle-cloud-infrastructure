#!/bin/bash
# Exit immediately if any command returns a non-zero status
# to run, use:
# sudo apply-wings-fixes
set -e

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: Please run this script using sudo: sudo $0"
  exit 1
fi

echo "===================================================="
echo "Starting Pterodactyl Wings Custom Fix Deployment"
echo "===================================================="

# --- FIX 1: DYNAMIC SSL DETECTION ---
echo "Step 1: Locating Caddy SSL certificates..."
CERT_PATH=$(find /srv/pterodactyl/caddy_data/caddy/certificates -name "*.crt" | head -n 1)

if [ -z "$CERT_PATH" ]; then
  echo "ERROR: No SSL certificate (.crt) found in /srv/pterodactyl/caddy_data/caddy/certificates"
  echo "Ensure Caddy is running and has generated certificates before running this fix."
  exit 1
fi

# Dynamically change extension from .crt to .key for the private key path
KEY_PATH="${CERT_PATH%.crt}.key"
if [ ! -f "$KEY_PATH" ]; then
  echo "ERROR: Corresponding private key (.key) not found at $KEY_PATH"
  exit 1
fi

echo "-> Found SSL Certificate: $CERT_PATH"
echo "-> Found Private Key:     $KEY_PATH"


# --- FIX 1 & 2: CONFIGURATION MERGE via PYTHON ---
echo "Step 2: Merging SSL paths and custom subnet mapping into config.yml..."
python3 -c "
import yaml
path = '/etc/pterodactyl/config.yml'

try:
    with open(path, 'r') as f:
        data = yaml.safe_load(f) or {}
except FileNotFoundError:
    print('Warning: config.yml not found. Creating a blank baseline.')
    data = {}

# Inject Fix 1: SSL configurations
if 'api' not in data: data['api'] = {}
data['api']['host'] = '0.0.0.0'
data['api']['port'] = 8080
if 'ssl' not in data['api']: data['api']['ssl'] = {}
data['api']['ssl']['enabled'] = True
data['api']['ssl']['cert'] = '$CERT_PATH'
data['api']['ssl']['key'] = '$KEY_PATH'

# Inject Fix 2: Custom isolated network routing 
# Safely traverse into interfaces -> v4
if 'interfaces' not in data['docker']['network']: data['docker']['network']['interfaces'] = {}
if 'v4' not in data['docker']['network']['interfaces']: data['docker']['network']['interfaces']['v4'] = {}

data['docker']['network']['interfaces']['v4']['subnet'] = '172.30.0.0/16'
data['docker']['network']['interfaces']['v4']['gateway'] = '172.30.0.1'
data['docker']['network']['interface'] = '172.30.0.1'

with open(path, 'w') as f:
    yaml.dump(data, f, default_flow_style=False)
"
echo "-> Configurations successfully injected into /etc/pterodactyl/config.yml!"


# --- CLEANUP AND RESTART ---
echo "Step 3: Pruning conflicting Docker networks..."
docker network prune -f

echo "Step 4: Restarting Wings systemd daemon..."
systemctl restart wings

echo "===================================================="
echo "SUCCESS: Custom modifications applied!"
echo "===================================================="
echo "Verifying Wings status:"
systemctl status wings --no-pager