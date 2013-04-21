#!/bin/sh
# Idempotent game server VM setup steps.

# Git URL that allows un-authenticated pulls.
GIT_PUBLIC_URL=git://github.com/netmap/netmap-game-server.git

# Git URL that allows pushes, but requires authentication.
GIT_PUSH_URL=git@github.com:netmap/netmap-game-server.git


# Build environment for gems with native extensions.
sudo apt-get install -y build-essential

# Easy way to add PPAs.
sudo apt-get install -y software-properties-common

# Git.
sudo apt-get install -y git

# nginx.
sudo apt-get install -y nginx

# nginx configuration for the game server.
sudo cp ~/vm/nginx/netmap-game.conf /etc/nginx/sites-available
sudo chown root:root /etc/nginx/sites-available/netmap-game.conf
sudo ln -s -f /etc/nginx/sites-available/netmap-game.conf \
              /etc/nginx/sites-enabled/netmap-game.conf
sudo rm -f /etc/nginx/sites-enabled/default

# Load the new configuration into nginx.
sudo /etc/init.d/nginx reload

# Postgres.
sudo apt-get install -y libpq-dev postgresql postgresql-client \
    postgresql-contrib postgresql-server-dev-all
if sudo -u postgres createuser --superuser $USER; then
  # Don't attempt to re-create the user's database if the user already exists.
  createdb $USER
fi

# PostGIS 2.
sudo add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable
sudo apt-get update -qq
sudo apt-get install -y postgis

# osm2pgsql
sudo debconf-set-selections <<'END'
openstreetmap-postgis-db-setup openstreetmap-postgis-db-setup/initdb boolean false
openstreetmap-postgis-db-setup openstreetmap-postgis-db-setup/grant_user string
openstreetmap-postgis-db-setup openstreetmap-postgis-db-setup/dbname string
END
sudo add-apt-repository -y ppa:kakrueger/openstreetmap  # osm2pgsql 0.81
sudo apt-get update -qq
sudo apt-get install -y osm2pgsql

# SQLite, because Rails is uncomfortable without it.
sudo apt-get install -y libsqlite3-dev sqlite3

# Ruby and Rubygems, used by the game server, which is written in Rails.
sudo apt-get install -y ruby ruby-dev
sudo env REALLY_GEM_UPDATE_SYSTEM=1 gem update --system 1.8.25

# Bundler, used to install all the gems in a Gemfile.
sudo gem install bundler

# Foreman sets up a system service to run the server as a daemon.
sudo gem install foreman

# Rake runs the commands in the server's Rakefile.
sudo gem install rake

# libv8, used by the therubyracer, chokes when installed by bundler.
sudo gem install therubyracer

# Mapnik, used to render map tiles.
sudo add-apt-repository -y ppa:mapnik/v2.1.0
sudo apt-get update -qq
sudo apt-get install -y libmapnik-dev mapnik-utils
sudo gem install ruby_mapnik


# If the game server repository is already checked out, update the code.
if [ -d ~/game ] ; then
  cd ~/game
  git checkout master
  git pull "$GIT_PUBLIC_URL" master
  bundle install
  rake db:migrate db:seed
fi

# Otherwise, check out the game server repository.
if [ ! -d ~/game ] ; then
  cd ~
  git clone "$GIT_PUBLIC_URL" game
  cd ~/game
  bundle install
  rake db:create db:migrate db:seed
  rake osm:create osm:load

  # Switch the repository URL to the one that accepts pushes.
  git remote rename origin public
  git remote add origin "$GIT_PUSH_URL"
fi

# Setup the game server daemon.
cd ~/game
sudo foreman export upstart /etc/init --app=netmap-game --procfile=Procfile \
    --env=.env --user=$USER --port=9000
sudo stop netmap-game
sudo start netmap-game
