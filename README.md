# Add links beteen two running container
## Fireup the containers
`sudo docker-compose up -d`
Creates two host container named `h1` and `h2` along with `ovs-vswitchd`.
## Add links between `h1` and `h2` via `ovs-vswitchd`
```
sudo bash createLink.sh h1 ovs-vswitchd
sudo bash createLink.sh h2 ovs-vswitchd
```