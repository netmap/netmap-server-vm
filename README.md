# NetMap Server VM Setup

This repository contains step-by-step instructions and scripts for using and/or
re-building a VM that closely resembles the NetMap production environment. This
VM is the recommended environment for working on the
[NetMap Game Server](https://github.com/netmap/netmap-game-server) and the
[NetMap Metrics Server](https://github.com/netmap/netmap-metrics-server).


## Use

[doc/use.md](doc/use.md) contains step-by-step instructions for downloading and
using a pre-built server VM.

[doc/build.md](doc/build.md) has the instructions for re-building the VM. This
can be useful for other projects, or for deploying a fork of the game server
into production.

### Scripts

[script/update.sh](script/update.sh) does the heavy lifting. Deploying a fork
of the game server will likely require many of the steps in that script.

[script/build.sh](script/build.sh)
If you don't live close to MIT, modify the `bbbike.org` URLs in
[lib/tasks/osm.rake](lib/tasks/osm.rake) to get OpenStreetMap data for your own
neighborhood, then run `rake osm:load`.


## Copyright

The NetMap server code is (C) Copyright Massachusetts Institute of Technology
2013, and is made available under the MIT license.
