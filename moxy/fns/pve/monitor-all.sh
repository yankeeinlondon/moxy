#!/usr/bin/env bash

# Copyright (c) 2021-2023 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

clear
cat <<"EOF"
    __  ___            _ __                ___    ____
   /  |/  /___  ____  (_) /_____  _____   /   |  / / /
  / /|_/ / __ \/ __ \/ / __/ __ \/ ___/  / /| | / / /
 / /  / / /_/ / / / / / /_/ /_/ / /     / ___ |/ / /
/_/  /_/\____/_/ /_/_/\__/\____/_/     /_/  |_/_/_/

EOF

add() {
while true; do
  read -r -p "This script will add Monitor All to Proxmox VE. Proceed(y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) exit ;;
  *) echo "Please answer yes or no." ;;
  esac
done

saveTemplate "pve-monitoring" "/var/log/ping-instances.log"

#done >> /var/log/ping-instances.log 2>&1' >/usr/local/bin/ping-instances.sh

# Change file permissions to executable
chmod +x /usr/local/bin/ping-instances.sh

# Create ping-instances.service
echo '[Unit]
Description=Ping instances every 5 minutes and restarts if necessary

[Service]
Type=simple
# To specify which CT/VM should be excluded, add the CT/VM ID at the end of the line where ExecStart=/usr/local/bin/ping-instances.sh is specified.
# For example: ExecStart=/usr/local/bin/ping-instances.sh 100 102
# Virtual machines without the QEMU guest agent installed must be excluded.
ExecStart=/usr/local/bin/ping-instances.sh
Restart=always
StandardOutput=file:/var/log/ping-instances.log
StandardError=file:/var/log/ping-instances.log

[Install]
WantedBy=multi-user.target' >/etc/systemd/system/ping-instances.service

# Reload daemon, enable and start ping-instances.service
systemctl daemon-reload
systemctl enable -q --now ping-instances.service
clear
echo -e "\n To view Monitor All logs: cat /var/log/ping-instances.log"
}

remove() {
  systemctl stop ping-instances.service
  systemctl disable ping-instances.service &>/dev/null
  rm /etc/systemd/system/ping-instances.service
  rm /usr/local/bin/ping-instances.sh
  rm /var/log/ping-instances.log
  echo "Removed Monitor All from Proxmox VE"
}

# Define options for the whiptail menu
OPTIONS=(Add "Add Monitor-All to Proxmox VE" \
         Remove "Remove Monitor-All from Proxmox VE")

# Show the whiptail menu and save the user's choice
CHOICE=$(whiptail --title "Monitor-All for Proxmox VE" --menu "Select an option:" 10 58 2 \
          "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

# Check the user's choice and perform the corresponding action
case $CHOICE in
  "Add")
    add
    ;;
  "Remove")
    remove
    ;;
  *)
    echo "Exiting..."
    exit 0
    ;;
esac
