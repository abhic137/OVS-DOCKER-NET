# Add links beteen two running container
## Fireup the containers
`sudo docker-compose up -d`
Creates two host container named `h1`, `h2` and `h3`.
It additionally creates `ovs-vswitchd`,`ovsdb-server`, and `ryu` controller.
## Add links between `h1` and `h2` via `ovs-vswitchd`
```
sudo bash createLink.sh h1 ovs-vswitchd
sudo bash createLink.sh h2 ovs-vswitchd
```