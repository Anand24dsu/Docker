#!/bin/bash

# Set environment variables (adjust as needed)
YB_VERSION=$(cat /packer_cache/variables.pkrvars.json | jq -r '.yb_version')
YB_INSTALL_DIR=/home/yugabyte/yugabyte-$YB_VERSION
PATH=$YB_INSTALL_DIR/bin:$PATH

# Switch to the yugabyte user
su - yugabyte << EOF

cd /home/yugabyte/yb_build
# Download and extract YugabyteDB
wget https://downloads.yugabyte.com/yugabyte-ce-${YB_VERSION}-linux-x86_64.tar.gz
tar -xzf yugabyte-ce-${YB_VERSION}-linux-x86_64.tar.gz
mv yugabyte-${YB_VERSION} ${YB_INSTALL_DIR}
rm yugabyte-ce-${YB_VERSION}-linux-x86_64.tar.gz

#run post install
${YB_INSTALL_DIR}/bin/post_install.sh

# Create a simple systemd service file (adjust paths as needed)
# Note: This is a very basic service file.  You'll likely need
# a more robust one for production.
cat <<EOT > /home/yugabyte/yugabyte.service
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

EOF
# Copy the service file to systemd and enable it
sudo cp /home/yugabyte/yugabyte.service /etc/systemd/system/
sudo systemctl enable yugabyte.service
sudo systemctl start yugabyte.service