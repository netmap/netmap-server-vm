#!/bin/sh
# VM setup/update bootstrap script.

set -o errexit  # Stop the script on the first error.
set -o nounset  # Catch un-initialized variables.

# Enable password-less sudo for the current user.
sudo sh -c "echo '$USER ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/$USER"

if [ "$USER" != "netmap" ] ; then
  # If this is not as netmap, create up the netmap user.
  if [ ! -d /home/netmap ] ; then
    sudo useradd --home-dir /home/netmap --create-home \
        --user-group --groups adm,sudo --shell $SHELL \
        --password $(echo "netmap" | openssl passwd -1 -stdin) netmap
  fi

  # Set up password-less sudo for the netmap user.
  sudo sh -c "echo 'netmap ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/netmap"
fi

# If the server VM repo is already checked out, run the update script in there.
if [ "$USER" = "netmap" ] ; then
  if [ -f /home/netmap/vm/script/update.sh ] ; then
    cd /home/netmap/vm
    git checkout master
    git pull --ff-only public master
    exec /home/netmap/vm/script/update.sh
  fi
fi

# Download and run the update script.
sudo -u netmap \
    sh -c 'curl -fLsS https://github.com/netmap/netmap-server-vm/raw/master/script/update.sh | sh -l'
