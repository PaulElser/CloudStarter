#!/bin/bash
# Make sure certbot is installed
# If not, run 'sudo apt-get install certbot'

# Replace this with your email address
EMAIL="me@paulelser.com"
# Replace this with your domain name
DOMAIN="*.paulelser.com"

# Generate the certificate
sudo certbot certonly --manual \
  --preferred-challenges=dns \
  --email $EMAIL \
  --server https://acme-v02.api.letsencrypt.org/directory \
  --agree-tos \
  -d $DOMAIN -d paulelser.com

# Copy the certificates to the correct directory for Traefik
sudo mkdir -p /etc/traefik/certs
sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/traefik/certs/
sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem /etc/traefik/certs/

# Set the correct permissions
sudo chown -R $(whoami):$(whoami) /etc/traefik/certs
sudo chmod 600 /etc/traefik/certs/*

echo "Certificates have been generated and prepared for Traefik."
