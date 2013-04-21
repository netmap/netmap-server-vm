#!/bin/sh
# VM setup/update bootstrap script.

set -o errexit  # Stop the script on the first error.
set -o nounset  # Catch un-initialized variables.

# Enable password-less sudo for the current user.
if ! sudo grep -q "$USER ALL=[\(]ALL:ALL[\)] NOPASSWD: ALL" /etc/sudoers ; then
  # This line should only be added once.
  sudo sh -c "echo $USER ALL=\(ALL:ALL\) NOPASSWD: ALL >> /etc/sudoers"
fi

if [ "$USER" != "netmap" ] ; then
  # If this is not as netmap, create up the netmap user.
  sudo useradd --home-dir /home/netmap --user-group --groups wheel \
      --password $(echo "netmap" | openssl passwd -1 -stdin) netmap

  # Set up password-less sudo for the netmap user.
  sudo sh -c "echo netmap ALL=\(ALL:ALL\) NOPASSWD: ALL >> /etc/sudoers"
fi

# If the server VM repo is already checked out, run the update script in there.
if [ "$USER" == "netmap" ] ; then
  if [ -f /home/netmap/vm/script/update.sh ] ; then
    cd /home/netmap/vm
    git checkout master
    git pull --ff-only public master
    exec /home/netmap/vm/script/update.sh
  fi
fi

# Download and run the update script.
sudo -u netmap \
    "bash -c 'curl -fLsS https://github.com/netmap/netmap-server-vm/raw/master/script/setup.sh | bash -l'"
