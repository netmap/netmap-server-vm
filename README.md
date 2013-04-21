# NetMap Server VM Setup

This repository contains step-by-step instructions and scripts for using and/or
re-building a VM that closely resembles the NetMap production environment. This
VM is the recommended environment for working on the
[NetMap Game Server](https://github.com/netmap/netmap-game-server) and the
[NetMap Metrics Server](https://github.com/netmap/netmap-metrics-server).


## Usage

[doc/use.md](doc/use.md) contains step-by-step instructions for downloading and
using a pre-built server VM.


## Building a VM

[doc/build.md](doc/build.md) has the instructions for re-building the VM. This
can be useful for other projects, or for deploying a fork of the game server
into production.

[script/update-game.sh](script/update-game.sh) lists all the dependencies for
the game server. Deploying a forked game server will likely require many of the
steps in that script. The script references the nginx configuration in
[nginx/netmap-game.conf](script/netmap-game.conf), which can also be useful for
deploying a forked game server.

Similarly, [script/update-metrics.sh](script/update-metrics.sh) and
[nginx/netmap-metrics.conf](script/netmap-metrics.conf) contain the setup for
the metrics server. These are mostly provided for intellectual curiosity, as we
kindly request that everyone uses the official NetMap metrics server.

The VM build instructions reference the bootstrap script at
[script/build.sh](script/build.sh), which uses
[script/update.sh](script/update.sh) to update the VM scripts repository, and
calls the other scripts mentioned above.


## Copyright

The NetMap server VM setup instructions and scripts are (C) Copyright
Massachusetts Institute of Technology 2013, and are made available under the
MIT license.
