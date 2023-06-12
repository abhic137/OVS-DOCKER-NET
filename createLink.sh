#!/bin/bash
## sudo bash createLink.sh <C1_name> <C2_Name>
C1_NAME=$1
C2_NAME=$2
##############################################################
createNS(){
	CONTAINER_ID=$1
	pid=$(docker inspect -f '{{.State.Pid}}' ${CONTAINER_ID})
	mkdir -p /var/run/netns/
	ln -sfT /proc/$pid/ns/net /var/run/netns/${CONTAINER_ID})
	#ip netns exec ${CONTAINER_ID}) ip a
	echo "Namespace Created for "${CONTAINER_ID}
}
#################################
addLink(){
	C1_ID=$1
	C2_ID=$2
	#ip netns exec ${CONTAINER_ID}) ip a
	echo "Namespace Created for "${CONTAINER_ID}
}
##############################################################
C1_ID=$(docker inspect --format="{{.Id}}" ${C1_NAME})
createNS(C1_ID)
C2_ID=$(docker inspect --format="{{.Id}}" ${C2_NAME})
createNS(C2_ID)

addLink(C1_ID,C2_ID)
