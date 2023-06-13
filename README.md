# Add links beteen two running container
## Fireup the containers
`sudo docker-compose up -d`
Creates two host container named `h1`, `h2` and `h3`.
It additionally creates `s1`,`ovsdb-server`, and `ryu` controller.
## Add links between `h1` and `h2` and bridge
### With brctl
* Create Links
```
sudo bash createLink.sh h1 h2
sudo bash createLink.sh h2 h3
```
* Create bridge in `h2`
```
sudo ip netns exec h2 brctl addbr switch1
sudo ip netns exec h2 iptables -A INPUT -i switch1 -j ACCEPT
sudo ip netns exec h2 iptables -A FORWARD -i switch1 -j ACCEPT
sudo ip netns exec h2 sysctl net.bridge.bridge-nf-call-arptables=0
sudo ip netns exec h2 sysctl net.bridge.bridge-nf-call-iptables=0
sudo ip netns exec h2 sysctl net.bridge.bridge-nf-call-ip6tables=0

sudo ip netns exec h2 ifconfig -a | grep dcp*| awk -F':' '{print $1}'   ## List interface names; Use Outputs as inputs of next CMD separately
sudo ip netns exec h2 brctl addif switch1 <ARG1>
sudo ip netns exec h2 brctl addif switch1 <ARG2> 
...
```
* Add IP to `h1` and `h3`
```
C1_IF=$(sudo ip netns exec h1 ifconfig -a | grep dcp*| awk -F':' '{print $1}')
sudo ip netns exec h1 ip a add 10.0.0.1/30 dev ${C1_IF}
C2_IF=$(sudo ip netns exec h3 ifconfig -a | grep dcp*| awk -F':' '{print $1}')
sudo ip netns exec h3 ip a add 10.0.0.2/30 dev ${C2_IF}
sudo ip netns exec h1 ip r add 10.0.0.2/32 via 0.0.0.0 dev ${C1_IF}
sudo ip netns exec h3 ip r add 10.0.0.1/32 via 0.0.0.0 dev ${C2_IF}
### Forward rules in Bridge
sudo ip netns exec h2 ip r add 10.0.0.1/32 via 0.0.0.0 dev ${C1_IF}
sudo ip netns exec h2 ip r add 10.0.0.2/32 via 0.0.0.0 dev ${C2_IF}
```

* Test
```
sudo ip netns exec h1 ping -c3 10.0.0.2
sudo ip netns exec h3 ping -c3 10.0.0.1
```

### OVS