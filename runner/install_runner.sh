#!/bin/bash

set -e

# Set variables
GITEA_URL="https://git.paulelser.com"
REPO_OWNER="pelser"
REPO_NAME="OneRing"
ACCESS_TOKEN="FhHeclbXhHe9oU1M9QZFhMLFIAXPr1LmNux15Gmu"
RUNNER_NAME="gitea-runner-$(hostname)"
INSTALL_DIR="/home/ubuntu/gitea_act_runner"

# Determine system architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64)
        ARCH="arm64"
        ;;
    armv7l)
        ARCH="arm-7"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Determine OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# Get the latest act_runner version and download URL
echo "Fetching the latest act_runner version and download URL..."
RELEASES_URL="https://gitea.com/api/v1/repos/gitea/act_runner/releases?limit=1"
RELEASE_INFO=$(curl -s "$RELEASES_URL")
RUNNER_VERSION=$(echo "$RELEASE_INFO" | grep -o '"tag_name":"[^"]*' | cut -d'"' -f4)
DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o '"browser_download_url":"[^"]*'"$OS-$ARCH" | cut -d'"' -f4 | head -n1)

if [ -z "$RUNNER_VERSION" ] || [ -z "$DOWNLOAD_URL" ]; then
    echo "Failed to fetch the latest version or download URL. Please check your internet connection and try again."
    exit 1
fi

echo "Latest act_runner version: $RUNNER_VERSION"
echo "Download URL: $DOWNLOAD_URL"

# Download the latest act_runner
echo "Downloading act_runner..."
wget -O act_runner_new "$DOWNLOAD_URL"

# Make the runner executable
chmod +x act_runner_new

# Create a directory for the runner (or clean it if it exists)
if [ -d "$INSTALL_DIR" ]; then
    echo "Cleaning existing installation directory..."
    rm -rf "$INSTALL_DIR"/*
else
    mkdir -p "$INSTALL_DIR"
fi

mv act_runner_new "$INSTALL_DIR/act_runner"

# Register the runner
cd "$INSTALL_DIR"
./act_runner register \
    --instance ${GITEA_URL} \
    --token ${ACCESS_TOKEN} \
    --name ${RUNNER_NAME} \
    --no-interactive

# Create a systemd service file
sudo tee /etc/systemd/system/act_runner.service > /dev/null << EOF
[Unit]
Description=Gitea act_runner
After=network.target

[Service]
ExecStart=${INSTALL_DIR}/act_runner daemon
WorkingDirectory=${INSTALL_DIR}
User=ubuntu
Group=ubuntu
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable act_runner
sudo systemctl start act_runner

echo "Gitea act_runner installed and started successfully."
