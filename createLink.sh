#!/bin/bash
## sudo bash createLink.sh <C1_name> <C2_Name>
C1_NAME=$1
C2_NAME=$2
##############################################################
createNS(){
	C_ID=$1
	#echo "Creating namespace for ${C_ID}"
	pid=$(docker inspect -f '{{.State.Pid}}' ${C_ID})
	CNAME=$(docker inspect --format='{{.Name}}' ${C_ID})
	echo "Name=${CNAME}, PID=${pid}"
	mkdir -p /var/run/netns/
	ln -sfT /proc/$pid/ns/net /var/run/netns/${CNAME}
	#ip netns exec ${CONTAINER_ID}) ip a
	echo "Namespace ${CNAME} Created for "${C_ID}
}
#################################
addLink(){
	C1_ID=$1
	C2_ID=$2
	#ip netns exec ${CONTAINER_ID}) ip a
	echo "Creating Link ..."
	ip link add veth1_l type veth peer veth1_r
	ip link set veth1_l netns ${C1_ID}
	ip link set veth1_r netns ${C2_ID}
	ip netns exec ${C1_ID} ip l set veth1_l name eth0
	ip netns exec ${C2_ID} ip l set veth1_r name eth0
	ip netns exec ${C1_ID} ip a add 10.0.0.1/30 dev eth0
	ip netns exec ${C2_ID} ip a add 10.0.0.2/30 dev eth0
	ip netns exec ${C1_ID} ip l set eth0 up
	ip netns exec ${C2_ID} ip l set eth0 up
	ip netns exec ${C1_ID} ip r add 0.0.0.0/0 via 10.0.0.2
	ip netns exec ${C2_ID} ip r add 0.0.0.0/0 via 10.0.0.1
}
##############################################################
C1_ID=$(docker inspect --format="{{.Id}}" ${C1_NAME})
createNS ${C1_ID}
C2_ID=$(docker inspect --format="{{.Id}}" ${C2_NAME})
createNS ${C2_ID}
##########
addLink ${C1_ID} ${C2_ID}



## sudo rm /var/run/netns/ #Cleanup