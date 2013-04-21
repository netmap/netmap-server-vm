#!/bin/sh
# Idempotent metrics server VM setup steps.

# Git URL that allows un-authenticated pulls.
GIT_PUBLIC_URL=git://github.com/netmap/netmap-metrics-server.git

# Git URL that allows pushes, but requires authentication.
GIT_PUSH_URL=git@github.com:netmap/netmap-metrics-server.git


# Build environment for node.js packages with native libraries.
sudo apt-get install -y build-essential

# Easy way to add PPAs.
sudo apt-get install -y software-properties-common

# Git.
sudo apt-get install -y git


# nginx.
sudo apt-get install -y nginx

# nginx configuration for the metrics server.
sudo cp ~/vm/nginx/netmap-metrics.conf /etc/nginx/sites-available
sudo chown root:root /etc/nginx/sites-available/netmap-metrics.conf
sudo ln -s /etc/nginx/sites-available/netmap-metrics.conf \
           /etc/nginx/sites-enabled/netmap-metrics.conf
sudo rm -f /etc/nginx/sites-enabled/default

# Load the new configuration into nginx.
sudo /etc/init.d/nginx reload


# Ruby and Rubygems, used by foreman, which runs the metrics server.
sudo apt-get install -y ruby ruby-dev
sudo env REALLY_GEM_UPDATE_SYSTEM=1 gem update --system

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


# If the metrics server repository is already checked out, update the code.
if [ -d ~/metrics ] ; then
  cd ~/metrics
  git checkout master
  git pull "$GIT_PUBLIC_URL" master
  npm install
  DATABASE_URL=postgres://127.0.0.1/netmap-metrics cake dbmigrate
fi

# Otherwise, check out the metrics server repository.
if [ ! -d ~/metrics ] ; then
  cd ~
  git clone "$GIT_PUBLIC_URL" metrics
  cd ~/metrics
  npm install
  createdb netmap-metrics
  DATABASE_URL=postgres://127.0.0.1/netmap-metrics cake dbmigrate

  # Switch the repository URL to the one that accepts pushes.
  git remote rename origin public
  git remote add origin "$GIT_PUSH_URL"
fi

# Setup the metrics server daemon.
cd ~/metrics
sudo foreman export upstart /etc/init --app=netmap-metrics \
    --procfile=Procfile --env=.env --user=$USER --port=11000
sudo stop netmap-metrics
sudo start netmap-metrics
