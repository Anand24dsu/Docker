#!/bin/bash

# Set non-interactive mode for apt
export DEBIAN_FRONTEND=noninteractive

# Update package lists and install necessary dependencies
sudo apt-get update && sudo apt-get install -y sudo wget gnupg2 lsb-release python-is-python3 python3

# Check Python version
python3 --version

# Download and extract YugabyteDB
YB_VERSION="2024.2.1.0"
YB_BUILD="b185"
YB_INSTALL_DIR="/home/yugabyte/yugabyte-${YB_VERSION}"

wget "https://downloads.yugabyte.com/releases/${YB_VERSION}/yugabyte-${YB_VERSION}-${YB_BUILD}-linux-x86_64.tar.gz"
tar xvfz "yugabyte-${YB_VERSION}-${YB_BUILD}-linux-x86_64.tar.gz"
sudo mv "yugabyte-${YB_VERSION}" /home/yugabyte/

# Run post-installation script
cd "$YB_INSTALL_DIR"
sudo ./bin/post_install.sh

# Create a systemd service file for YugabyteDB
cat <<EOT | sudo tee /etc/systemd/system/yugabyte.service
[Unit]
Description=YugabyteDB
After=network.target

[Service]
User=yugabyte
WorkingDirectory=${YB_INSTALL_DIR}
ExecStart=${YB_INSTALL_DIR}/bin/yugabyted start --base_dir=/home/yugabyte/yb_data
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

# Ensure Yugabyte user and necessary directories exist
sudo useradd -m -s /bin/bash yugabyte || true
sudo mkdir -p /home/yugabyte/yb_data
sudo chown -R yugabyte:yugabyte /home/yugabyte

# Reload systemd, enable, and start YugabyteDB service
sudo systemctl daemon-reload
sudo systemctl enable yugabyte.service
sudo systemctl start yugabyte.service

echo "Provisioning complete"
