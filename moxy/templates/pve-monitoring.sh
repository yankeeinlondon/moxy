#!/usr/bin/env bash

# template: used by monitor-all.sh

# Read excluded instances from command line arguments
excluded_instances=("$@")
echo "Excluded instances: ${excluded_instances[@]}"

while true; do

  for instance in $(pct list | awk '\''{if(NR>1) print $1}'\''; qm list | awk '\''{if(NR>1) print $1}'\''); do
    # Skip excluded instances
    if [[ " ${excluded_instances[@]} " =~ " ${instance} " ]]; then
      continue
    fi

    # Determine the type of the instance (container or virtual machine)
    if pct status $instance >/dev/null 2>&1; then
      # It is a container
      config_cmd="pct config"
      IP=$(pct exec $instance ip a s dev eth0 | awk '\''/inet / {print $2}'\'' | cut -d/ -f1)
    else
      # It is a virtual machine
      config_cmd="qm config"
      IP=$(qm guest cmd $instance network-get-interfaces | egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -E "192\.|10\.")
    fi

    # Skip instances based on templates
    template=$($config_cmd $instance | grep template | grep -q "template:" && echo "true" || echo "false")
    if [ "$template" == "true" ]; then
      echo "Skipping $instance because it is a template"
      continue
    fi

    # Ping the instance
    if ! ping -c 1 $IP >/dev/null 2>&1; then
      # If the instance can not be pinged, stop and start it
      if pct status $instance >/dev/null 2>&1; then
        # It is a container
        echo "$(date): CT $instance is not responding, restarting..."
        pct stop $instance >/dev/null 2>&1
        sleep 5
        pct start $instance >/dev/null 2>&1
      else
        # It is a virtual machine
        if qm status $instance | grep -q "status: running"; then
          echo "$(date): VM $instance is not responding, resetting..."
          qm reset $instance >/dev/null 2>&1
        else
          qm start $instance >/dev/null 2>&1
          echo "$(date): VM $instance is not running, starting..."
        fi
      fi
    fi
  done

  # Wait for 5 minutes. (Edit to your needs)
  echo "$(date): Pausing for 5 minutes..."
  sleep 300
done >> /var/log/ping-instances.log 2>&1' >/usr/local/bin/ping-instances.sh

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
WantedBy=multi-user.target
'
