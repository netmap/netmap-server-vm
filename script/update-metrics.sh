#!/bin/sh
# Idempotent metrics server VM setup steps.

# Git URL that allows un-authenticated pulls.
GIT_PUBLIC_URL=git://github.com/netmap/netmap-metrics-server.git

# Git URL that allows pushes, but requires authentication.
GIT_PUSH_URL=git@github.com:netmap/netmap-metrics-server.git

set -o errexit  # Stop the script on the first error.
set -o nounset  # Catch un-initialized variables.

# Build environment for node.js packages with native libraries.
sudo apt-get install -y build-essential

# Easy way to add PPAs.
sudo apt-get install -y software-properties-common

# Git.
sudo apt-get install -y git


# nginx.
sudo apt-get install -y nginx

# nginx configuration for the metrics server.
if [ -f /etc/netmap/prod.keys ] ; then
  sudo cp ~/vm/nginx/prod/netmap-metrics.conf /etc/nginx/sites-available
fi
if [ ! -f /etc/netmap/prod.keys ] ; then
  sudo cp ~/vm/nginx/netmap-metrics.conf /etc/nginx/sites-available
fi
sudo chown root:root /etc/nginx/sites-available/netmap-metrics.conf
sudo ln -s -f /etc/nginx/sites-available/netmap-metrics.conf \
              /etc/nginx/sites-enabled/netmap-metrics.conf
sudo rm -f /etc/nginx/sites-enabled/default

# Load the new configuration into nginx.
sudo /etc/init.d/nginx reload


# Ruby and Rubygems, used by foreman, which runs the metrics server.
sudo apt-get install -y ruby ruby-dev
sudo env REALLY_GEM_UPDATE_SYSTEM=1 gem update --system 1.8.25

# Foreman sets up a system service to run the metrics server as a daemon.
sudo gem install foreman


# Postgres.
sudo apt-get install -y libpq-dev postgresql postgresql-client \
    postgresql-contrib postgresql-server-dev-all
if sudo -u postgres createuser --superuser $USER; then
  # Don't attempt to re-create the user's database if the user already exists.
  createdb $USER
fi

# Configure postgres to use ident authentication over TCP.
sudo ruby <<"EOF"
pg_file = Dir['/etc/postgresql/**/pg_hba.conf'].first
lines = File.read(pg_file).split("\n")
lines.each do |line|
  next unless /^host.*127\.0\.0\.1.*md5$/ =~ line
  line.gsub! 'md5', 'ident'
end
File.open(pg_file, 'w') { |f| f.write lines.join("\n") }
EOF
sudo /etc/init.d/postgresql restart

# Ident server used by the node.js postgres connection.
sudo apt-get install -y oidentd


# node.js
sudo add-apt-repository -y ppa:chris-lea/node.js
sudo apt-get update -qq
sudo apt-get install -y nodejs

# CoffeeScript provides cake, which runs the Cakefile in the metrics server.
npm cache add coffee-script
sudo npm install -g coffee-script


# If the metrics server repository is already checked out, update the code.
if [ -d ~/metrics ] ; then
  cd ~/metrics
  git checkout master
  git pull --ff-only "$GIT_PUBLIC_URL" master
fi

# Otherwise, check out the metrics server repository.
if [ ! -d ~/metrics ] ; then
  cd ~
  git clone "$GIT_PUBLIC_URL" metrics
  cd ~/metrics
  createdb netmap-metrics

  # Switch the repository URL to the one that accepts pushes.
  git remote rename origin public
  git remote add origin "$GIT_PUSH_URL"
fi

# Update packages and the database.
cd ~/metrics
npm install
DATABASE_URL=postgres://127.0.0.1/netmap-metrics cake dbmigrate
if [ ! -f /etc/netmap/prod.keys ] ; then
  cake devapp
fi

# Setup the metrics server daemon.
cd ~/metrics
if [ -f /etc/netmap/prod.keys ] ; then
  sudo foreman export upstart /etc/init --app=netmap-metrics \
      --procfile=Procfile --env=production.env --user=$USER --port=11000
fi
if [ ! -f /etc/netmap/prod.keys ] ; then
  sudo foreman export upstart /etc/init --app=netmap-metrics \
      --procfile=Procfile --env=.env --user=$USER --port=11000
fi

# 'stop' will fail during the initial setup, so ignore it's exit status.
sudo stop netmap-metrics || echo 'Ignore the error above during initial setup'
sudo start netmap-metrics
