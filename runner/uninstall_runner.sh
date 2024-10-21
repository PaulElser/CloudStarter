#!/bin/bash

INSTALL_DIR="/home/ubuntu/gitea_act_runner"

# Stop and remove the existing service
sudo systemctl stop act_runner
sudo systemctl disable act_runner
sudo rm /etc/systemd/system/act_runner.service
sudo systemctl daemon-reload

# Remove the existing installation
rm -rf "$INSTALL_DIR"
