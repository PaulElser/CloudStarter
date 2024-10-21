#!/bin/bash

# Set variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITEA_HOME="${GITEA_HOME:-$SCRIPT_DIR/gitea}"
BACKUP_DIR="${BACKUP_DIR:-$SCRIPT_DIR/backups}"
CERT_DIR="${CERT_DIR:-$SCRIPT_DIR/certs}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="gitea_backup_$TIMESTAMP"

# Create backup directory
mkdir -p "$BACKUP_DIR/$BACKUP_NAME"

# Backup repositories
echo "Backing up repositories..."
cp -R "$GITEA_HOME/git/repositories" "$BACKUP_DIR/$BACKUP_NAME/"

# Backup database (assuming SQLite, adjust if using a different database)
echo "Backing up database..."
cp "$GITEA_HOME/gitea/gitea.db" "$BACKUP_DIR/$BACKUP_NAME/"

# Backup configuration
echo "Backing up configuration..."
cp "$GITEA_HOME/gitea/conf/app.ini" "$BACKUP_DIR/$BACKUP_NAME/"

# Backup custom files
echo "Backing up custom files..."
[ -d "$GITEA_HOME/gitea/custom" ] && cp -R "$GITEA_HOME/gitea/custom" "$BACKUP_DIR/$BACKUP_NAME/"

# Backup data files
echo "Backing up data files..."
cp -R "$GITEA_HOME/gitea/data" "$BACKUP_DIR/$BACKUP_NAME/"

# Backup SSH keys
echo "Backing up SSH keys..."
[ -d "$GITEA_HOME/ssh" ] && cp -R "$GITEA_HOME/ssh" "$BACKUP_DIR/$BACKUP_NAME/"

# Backup certificates
echo "Backing up certificates..."
mkdir -p "$BACKUP_DIR/$BACKUP_NAME/certs"
cp "$CERT_DIR/fullchain.pem" "$BACKUP_DIR/$BACKUP_NAME/certs/" || echo "Warning: fullchain.pem not found"
cp "$CERT_DIR/privkey.pem" "$BACKUP_DIR/$BACKUP_NAME/certs/" || echo "Warning: privkey.pem not found"

# Backup certificates.toml
echo "Backing up certificates.toml..."
cp "$SCRIPT_DIR/certificates.toml" "$BACKUP_DIR/$BACKUP_NAME/" || echo "Warning: certificates.toml not found"

# Create a tarball of the backup
echo "Creating tarball..."
tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" -C "$BACKUP_DIR" "$BACKUP_NAME"

# Remove the temporary backup directory
rm -rf "$BACKUP_DIR/$BACKUP_NAME"

echo "Backup completed: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
