#!/bin/bash

set -e

# Function to display script usage
usage() {
    echo "Usage: $0 <backup_file.tar.gz>"
    echo "Environment variables:"
    echo "  GITEA_HOME: Path to Gitea data directory (default: ./gitea)"
    echo "  GITEA_USER: User ID of Gitea process (default: 1000)"
    echo "  GITEA_GROUP: Group ID of Gitea process (default: 1000)"
    echo "  CERT_DIR: Path to certificate directory (default: ./certs)"
    exit 1
}

# Check if backup file is provided
if [ $# -eq 0 ]; then
    usage
fi

BACKUP_FILE=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITEA_HOME="${GITEA_HOME:-$SCRIPT_DIR/gitea}"
GITEA_USER="${GITEA_USER:-1000}"
GITEA_GROUP="${GITEA_GROUP:-1000}"
CERT_DIR="${CERT_DIR:-$SCRIPT_DIR/certs}"
TEMP_RESTORE_DIR="/tmp/gitea_restore_$(date +%s)"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file $BACKUP_FILE not found!"
    exit 1
fi

# Check if Gitea home directory exists
if [ ! -d "$GITEA_HOME" ]; then
    echo "Error: Gitea home directory $GITEA_HOME not found!"
    exit 1
fi

# Create temporary directory for restoration
mkdir -p "$TEMP_RESTORE_DIR"

echo "Extracting backup to temporary directory..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_RESTORE_DIR"

# Find the extracted directory (it may have a timestamp in the name)
EXTRACTED_DIR=$(find "$TEMP_RESTORE_DIR" -maxdepth 1 -type d | grep -v "^$TEMP_RESTORE_DIR$")

if [ -z "$EXTRACTED_DIR" ]; then
    echo "Error: Could not find extracted directory in $TEMP_RESTORE_DIR"
    exit 1
fi

echo "Stopping Gitea service..."
docker compose down

echo "Restoring Gitea data..."

# Restore repositories
cp -R "$EXTRACTED_DIR/repositories/"* "$GITEA_HOME/git/repositories/"

# Restore database (assuming SQLite)
cp "$EXTRACTED_DIR/gitea.db" "$GITEA_HOME/gitea/"

# Restore configuration
cp "$EXTRACTED_DIR/app.ini" "$GITEA_HOME/gitea/conf/"

# Restore custom files
if [ -d "$EXTRACTED_DIR/custom" ]; then
    cp -R "$EXTRACTED_DIR/custom/"* "$GITEA_HOME/gitea/custom/"
fi

# Restore data files
#cp -R "$EXTRACTED_DIR/data/"* "$GITEA_HOME/gitea/data/"

# Restore SSH keys
if [ -d "$EXTRACTED_DIR/ssh" ]; then
    cp -R "$EXTRACTED_DIR/ssh/"* "$GITEA_HOME/ssh/"
fi

echo "Restoring certificates..."
# Ensure the certificate directory exists
mkdir -p "$CERT_DIR"

# Restore certificates
if [ -f "$EXTRACTED_DIR/certs/fullchain.pem" ] && [ -f "$EXTRACTED_DIR/certs/privkey.pem" ]; then
    cp "$EXTRACTED_DIR/certs/fullchain.pem" "$CERT_DIR/"
    cp "$EXTRACTED_DIR/certs/privkey.pem" "$CERT_DIR/"
    echo "Certificates restored successfully."
else
    echo "Warning: Certificates not found in the backup. You may need to regenerate them."
fi

# Restore certificates.toml if it exists in the backup
if [ -f "$EXTRACTED_DIR/certificates.toml" ]; then
    cp "$EXTRACTED_DIR/certificates.toml" "$SCRIPT_DIR/"
    echo "certificates.toml restored successfully."
else
    echo "Warning: certificates.toml not found in the backup. Using existing file if present."
fi

echo "Setting correct ownership..."
chown -R $GITEA_USER:$GITEA_GROUP "$GITEA_HOME"
chown -R $GITEA_USER:$GITEA_GROUP "$CERT_DIR"

echo "Cleaning up temporary files..."
rm -rf "$TEMP_RESTORE_DIR"

echo "Starting Gitea service..."
docker compose up -d

echo "Restoration complete!"
echo "Please verify that your Gitea instance is working correctly."
echo "If you experience any issues, check the Gitea logs and consider running 'gitea admin regenerate keys'"
echo "Also, ensure that your certificates are valid and properly configured in Traefik."
