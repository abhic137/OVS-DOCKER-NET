# Build Containers
## OVS
`sudo docker pull openvswitch/ovs:2.11.2_debian`
`sudo docker tag openvswitch/ovs:2.11.2_debian openvswitch/ovs:latest`
## RYU
`sudo docker pull osrg/ryu`
## Host
`sudo docker build -f Dockerfile.Ubuntu -t host:latest .`
## Fireup the containers
`sudo docker-compose up -d`
Creates two host container named `h1`, `h2` and `h3`.
It additionally creates `s1`,`ovsdb-server`, and `ryu` controller.

# Add links beteen two running container
## Add links between `h1` and `h2` and bridge
### With brctl <span style="color:blue"> Not working exactly </span>
* Create Links
```
sudo bash createLink.sh h1 h2
sudo bash createLink.sh h2 h3
```
* Create bridge in `h2`
```
sudo apt-get install bridge-utils
sudo ip netns exec h2 brctl addbr switch1
sudo ip netns exec h2 iptables -A INPUT -i switch1 -j ACCEPT
sudo ip netns exec h2 iptables -A FORWARD -i switch1 -j ACCEPT
sudo ip netns exec h2 sysctl net.bridge.bridge-nf-call-arptables=0
sudo ip netns exec h2 sysctl net.bridge.bridge-nf-call-iptables=0
sudo ip netns exec h2 sysctl net.bridge.bridge-nf-call-ip6tables=0

   ## List interface names; Use Outputs as inputs of next CMD separately
### Untested
sudo ip netns exec h2 ifconfig -a | grep dcp*| awk -F':' '{print $1}' | xargs -I {} echo sudo ip netns exec h2 brctl addif switch1 $1 {};
### Tested
sudo ip netns exec h2 ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}'
sudo ip netns exec h2 brctl addif switch1 <ARG1>
sudo ip netns exec h2 brctl addif switch1 <ARG2> 
...
```
* Add IP to `h1` and `h3`
```
C1_IF=$(sudo ip netns exec h1 ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}')
sudo ip netns exec h1 ip a add 10.0.0.1/30 dev ${C1_IF}
C2_IF=$(sudo ip netns exec h3 ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}')
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

### OVS (Without Controller)
* Create Links
```
sudo bash createLink.sh h1 s1
sudo bash createLink.sh h2 s1
```
* Create bridge in `s1`
```
sudo docker exec s1 ovs-vsctl add-br br0
sudo ip netns exec s1 ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}'   ## List interface names; Use Outputs as inputs of next CMD separately
sudo docker exec s1 ovs-vsctl add-port br0 <INTF1>
sudo docker exec s1 ovs-vsctl add-port br0 <INTF2>
...
sudo docker exec s1 ovs-vsctl set-fail-mode br0 standalone
```
* Add IP to `h1` and `h2`
```
C1_IF=$(sudo ip netns exec h1 ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}')
sudo ip netns exec h1 ip a add 10.0.0.1/30 dev ${C1_IF}
C2_IF=$(sudo ip netns exec h2 ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}')
sudo ip netns exec h2 ip a add 10.0.0.2/30 dev ${C2_IF}
sudo ip netns exec h1 ip r add 10.0.0.2/32 via 0.0.0.0 dev ${C1_IF}
sudo ip netns exec h2 ip r add 10.0.0.1/32 via 0.0.0.0 dev ${C2_IF}
```

* Test
```
sudo docker exec h1 ping -c3 10.0.0.2
sudo docker exec h2 ping -c3 10.0.0.1
```
### OVS (With Ryu)

    * Create Links
```
sudo bash createLink.sh h1 s1
sudo bash createLink.sh h2 s1
```
   * Create bridge in s1
```
sudo docker exec s1 ovs-vsctl add-br br0
sudo ip netns exec s1 ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}'   ## List interface names; Use Outputs as inputs of next CMD separately
sudo docker exec s1 ovs-vsctl add-port br0 <INTF1>
sudo docker exec s1 ovs-vsctl add-port br0 <INTF2>
sudo docker exec s1 ovs-vsctl set-fail-mode br0 secure
```
   * Add IP to h1 and h2
```
C1_IF=$(sudo ip netns exec h1 ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}')
sudo ip netns exec h1 ip a add 10.0.0.1/30 dev ${C1_IF}
C2_IF=$(sudo ip netns exec h2 ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}')
sudo ip netns exec h2 ip a add 10.0.0.2/30 dev ${C2_IF}
sudo ip netns exec h1 ip r add 10.0.0.2/32 via 0.0.0.0 dev ${C1_IF}
sudo ip netns exec h2 ip r add 10.0.0.1/32 via 0.0.0.0 dev ${C2_IF}
```

* Add controller to the ovs
```
sudo docker exec s1 ovs-vsctl set-controller br0 tcp:172.18.0.4:6653
```
* Inside the ryu container
```
cd ryu/ryu/app
ryu-manager --observe-links simple_switch.py 
```
* Test
```
sudo docker exec h1 ping -c3 10.0.0.2
sudo docker exec h2 ping -c3 10.0.0.1
```



* Save docker images
```
docker images
sudo docker save <image_name_or_id> > <name>.tar
```
* Split docker images
```
split --verbose -b 200M ryu:latest.tar ryu:latest.tar.part
```
* recombine
```
cat oai-gnb_latest.tar.a? > oai-gnb_latest_18.tar
```
* Create Docker image
```
sudo docker load --input oai-gnb_latest_18.tar
sudo docker tag <Image-ID> oai-gnb:latest
```

