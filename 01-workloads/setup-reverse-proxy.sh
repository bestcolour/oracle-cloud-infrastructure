#!/bin/bash

################################################################################
# STEP 1: DEFINE VARIABLES
# Fill in these values to match your OCI environment and backend setup.
################################################################################

# The internal IP address of your application server in the private subnet
BACKEND_PRIVATE_IP="10.0.1.x" 

# The port your backend application is listening on (e.g., 8080, 3000)
BACKEND_PORT="8080"

# The domain name or public IP of this proxy instance
DOMAIN_NAME="your_domain_or_public_ip"

################################################################################
# STEP 2: SYSTEM UPDATE & NGINX INSTALLATION
################################################################################

# Update the package index and upgrade existing packages
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Nginx
sudo apt-get install nginx -y

# Ensure Nginx starts on boot and is currently running
sudo systemctl enable nginx
sudo systemctl start nginx

################################################################################
# STEP 3: CONFIGURE ORACLE CLOUD (UBUNTU) FIREWALL
# OCI Ubuntu images use 'iptables' by default. We must open port 80/443.
################################################################################

# Allow HTTP and HTTPS traffic through the local OS firewall
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT

# Save the iptables rules to ensure they persist after reboot
sudo netfilter-persistent save

################################################################################
# STEP 4: CREATE REVERSE PROXY CONFIGURATION
################################################################################

# Remove the default Nginx configuration file
sudo rm /etc/nginx/sites-enabled/default

# Create a new configuration file for the reverse proxy
cat <<EOF | sudo tee /etc/nginx/sites-available/reverse_proxy
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        # Redirect traffic to the private instance
        proxy_pass http://$BACKEND_PRIVATE_IP:$BACKEND_PORT;
        
        # Pass essential headers to the backend
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the configuration by creating a symbolic link
sudo ln -s /etc/nginx/sites-available/reverse_proxy /etc/nginx/sites-enabled/

################################################################################
# STEP 5: VALIDATE AND RESTART
################################################################################

# Check if the Nginx configuration syntax is correct
sudo nginx -t

# If successful, restart Nginx to apply changes
if [ $? -eq 0 ]; then
    sudo systemctl restart nginx
    echo "Nginx Reverse Proxy setup successfully."
else
    echo "Nginx configuration test failed. Please check the logs."
    exit 1
fi