#!/bin/sh
# Idempotent server SSL keys setup steps.

# Git URL.
if [ -f /etc/netmap/prod.keys ] ; then
  # In production, prod.keys points to the keys repository.
  GIT_URL="$(cat /etc/netmap/prod.keys)"
fi
if [ ! -f /etc/netmap/prod.keys ] ; then
  # Use the public devkeys in the development VMs.
  GIT_URL=git://github.com/netmap/netmap-dev-keys.git
fi

# Git.
sudo apt-get install -y git

# If the SSL keys repository is already checked out, update the code.
if [ -d ~/keys ] ; then
  cd ~/keys
  git checkout master
  git pull --ff-only "$GIT_URL" master
fi

# Otherwise, check out the SSL keys repository.
if [ ! -d ~/keys ] ; then
  cd ~
  git clone "$GIT_URL" keys
fi

# Make sure the keys aren't readable by other users.
cd ~/keys
chmod 0600 *
