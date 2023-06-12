#!/bin/bash
## sudo bash createLink.sh <C1_name> <C2_Name>
C1_NAME=$1
C2_NAME=$2

pid=$(docker inspect -f '{{.State.Pid}}' ${container_id})
mkdir -p /var/run/netns/
ln -sfT /proc/$pid/ns/net /var/run/netns/${container_id})
ip netns exec ${container_id}) ip a
