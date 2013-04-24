# Production Deployment Instructions

The VM setup scripts can be used to deploy a forked game server into
production.


## Production Keys

Production deployments should not use the NetMap development SSL keys or API
keys. Read the
[keys repository docs](https://github.com/netmap/netmap-dev-keys/blob/master/README.md)
and set up your own keys repository.

The git URL to the keys repository should be saved in `/etc/netmap/keys.prod`
on your production server. The existence of this file tells the VM scripts to
configure a production server.

```bash
sudo mkdir /etc/netmap
sudo sh -c 'echo "https://you@github.com/you/private-keys-repo.git" > /etc/netmap/keys.prod
```

## Game Server Setup

Create the file `/etc/netmap/game` to tell the VM scripts to set up a game
server in production mode.

```bash
sudo touch /etc/netmap/game
```

Kick off the VM setup script. After one sudo prompt, the script will run on its
own for a while.

```bash
curl -fLsS https://github.com/netmap/netmap-server-vm/raw/master/script/setup.sh | sh
```

