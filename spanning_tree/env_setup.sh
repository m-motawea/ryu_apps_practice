#!/bin/bash

set -e

echo "enabling ip forwarding"
sudo sh -c "echo '1' > /proc/sys/net/ipv4/ip_forward"

echo "creating of-switch-1 (OVS Bridge) as pure OpenFlow1.3 switch"
sudo ovs-vsctl add-br of-switch-1
sudo ovs-vsctl set bridge of-switch-1 protocols=OpenFlow13
sudo ovs-vsctl set bridge of-switch-1 other-config:datapath_id=0000000000000001
sudo ovs-ofctl -O OpenFlow13 del-flows of-switch-1
sudo ovs-vsctl set-controller of-switch-1 tcp:127.0.0.1:6633

echo "creating of-switch-2 (OVS Bridge) as pure OpenFlow1.3 switch"
sudo ovs-vsctl add-br of-switch-2
sudo ovs-vsctl set bridge of-switch-2 protocols=OpenFlow13
sudo ovs-vsctl set bridge of-switch-2 other-config:datapath_id=0000000000000002
sudo ovs-ofctl -O OpenFlow13 del-flows of-switch-2
sudo ovs-vsctl set-controller of-switch-2 tcp:127.0.0.1:6633

echo "creating of-switch-3 (OVS Bridge) as pure OpenFlow1.3 switch"
sudo ovs-vsctl add-br of-switch-3
sudo ovs-vsctl set bridge of-switch-3 protocols=OpenFlow13
sudo ovs-vsctl set bridge of-switch-3 other-config:datapath_id=0000000000000003
sudo ovs-ofctl -O OpenFlow13 del-flows of-switch-3
sudo ovs-vsctl set-controller of-switch-3 tcp:127.0.0.1:6633


echo "linking (of-switch-1 & of-switch-2) with veth pairs and OF_PORT=10"
sudo ip link add s1-s2 type veth peer name s2-s1
sudo ovs-vsctl add-port of-switch-1 s1-s2
sudo ovs-vsctl set Interface s1-s2 ofport_request=10
sudo ip link set s1-s2 up
sudo ovs-vsctl add-port of-switch-2 s2-s1
sudo ovs-vsctl set Interface s2-s1 ofport_request=10
sudo ip link set s2-s1 up

echo "linking (of-switch-1 & of-switch-3) with veth pairs and OF_PORT=20"
sudo ip link add s1-s3 type veth peer name s3-s1
sudo ovs-vsctl add-port of-switch-1 s1-s3
sudo ovs-vsctl set Interface s1-s3 ofport_request=20
sudo ip link set s1-s3 up
sudo ovs-vsctl add-port of-switch-3 s3-s1
sudo ovs-vsctl set Interface s3-s1 ofport_request=20
sudo ip link set s3-s1 up

echo "linking (of-switch-1 & of-switch-2) with veth pairs and OF_PORT=30"
sudo ip link add s2-s3 type veth peer name s3-s2
sudo ovs-vsctl add-port of-switch-2 s2-s3
sudo ovs-vsctl set Interface s2-s3 ofport_request=30
sudo ip link set s2-s3 up
sudo ovs-vsctl add-port of-switch-3 s3-s2
sudo ovs-vsctl set Interface s3-s2 ofport_request=10
sudo ip link set s3-s2 up

#echo "linking (of-switch-1 & of-switch-2) with patch ports and OF_PORT=10"
#
#echo "creating patch port in of-switch-1"
#sudo ovs-vsctl add-port of-switch-1 p1-sw1
#sudo ovs-vsctl set Interface p1-sw1 ofport_request=10
#sudo ovs-vsctl set Interface p1-sw1 type=patch
#sudo ovs-vsctl set Interface p1-sw1 options:peer=p1-sw2
#echo "creating patch port in of-switch-2"
#sudo ovs-vsctl add-port of-switch-2 p1-sw2
#sudo ovs-vsctl set Interface p1-sw2 ofport_request=10
#sudo ovs-vsctl set Interface p1-sw2 type=patch
#sudo ovs-vsctl set Interface p1-sw2 options:peer=p1-sw1
#
#echo "linking (of-switch-1 & of-switch-3) with patch ports and OF_PORT=20"
#
#echo "creating patch port in of-switch-1"
#sudo ovs-vsctl add-port of-switch-1 p2-sw1
#sudo ovs-vsctl set Interface p2-sw1 ofport_request=20
#sudo ovs-vsctl set Interface p2-sw1 type=patch
#sudo ovs-vsctl set Interface p2-sw1 options:peer=p2-sw3
#echo "creating patch port in of-switch-3"
#sudo ovs-vsctl add-port of-switch-3 p2-sw3
#sudo ovs-vsctl set Interface p2-sw3 ofport_request=20
#sudo ovs-vsctl set Interface p2-sw3 type=patch
#sudo ovs-vsctl set Interface p2-sw3 options:peer=p2-sw1
#
#echo "linking (of-switch-2 & of-switch-3) with patch ports and OF_PORT=30"
#
#echo "creating patch port in of-switch-3"
#sudo ovs-vsctl add-port of-switch-3 p3-sw3
#sudo ovs-vsctl set Interface p3-sw3 ofport_request=30
#sudo ovs-vsctl set Interface p3-sw3 type=patch
#sudo ovs-vsctl set Interface p3-sw3 options:peer=p3-sw2
#echo "creating patch port in of-switch-2"
#sudo ovs-vsctl add-port of-switch-2 p3-sw2
#sudo ovs-vsctl set Interface p3-sw2 ofport_request=30
#sudo ovs-vsctl set Interface p3-sw2 type=patch
#sudo ovs-vsctl set Interface p3-sw2 options:peer=p3-sw3

echo "creating h1 namespace with ip 10.10.10.1/24 and OF_PORT=1 on of-switch-1"
sudo ip netns add h1
sudo ip link add h1-ns type veth peer name h1-sw
sudo ip link set netns h1 h1-ns
sudo ip netns exec h1 ip addr add 10.10.10.1/24 dev h1-ns
sudo ip netns exec h1 ifconfig h1-ns up
sudo ovs-vsctl add-port of-switch-1 h1-sw
sudo ovs-vsctl set Interface h1-sw ofport_request=1
sudo ifconfig h1-sw up

echo "creating h2 namespace with ip 10.10.10.2/24 and OF_PORT=2 on of-switch-1"
sudo ip netns add h2
sudo ip link add h2-ns type veth peer name h2-sw
sudo ip link set netns h2 h2-ns
sudo ip netns exec h2 ip addr add 10.10.10.2/24 dev h2-ns
sudo ip netns exec h2 ifconfig h2-ns up
sudo ovs-vsctl add-port of-switch-1 h2-sw
sudo ovs-vsctl set Interface h2-sw ofport_request=2
sudo ifconfig h2-sw up

echo "creating h3 namespace with ip 10.10.10.3/24 and OF_PORT=3 on of-switch-2"
sudo ip netns add h3
sudo ip link add h3-ns type veth peer name h3-sw
sudo ip link set netns h3 h3-ns
sudo ip netns exec h3 ip addr add 10.10.10.3/24 dev h3-ns
sudo ip netns exec h3 ifconfig h3-ns up
sudo ovs-vsctl add-port of-switch-2 h3-sw
sudo ovs-vsctl set Interface h3-sw ofport_request=3
sudo ifconfig h3-sw up

echo "creating h4 namespace with ip 10.10.10.4/24 and OF_PORT=4 on of-switch-2"
sudo ip netns add h4
sudo ip link add h4-ns type veth peer name h4-sw
sudo ip link set netns h4 h4-ns
sudo ip netns exec h4 ip addr add 10.10.10.4/24 dev h4-ns
sudo ip netns exec h4 ifconfig h4-ns up
sudo ovs-vsctl add-port of-switch-2 h4-sw
sudo ovs-vsctl set Interface h4-sw ofport_request=4
sudo ifconfig h4-sw up

echo "creating h5 namespace with ip 10.10.10.5/24 and OF_PORT=5 on of-switch-3"
sudo ip netns add h5
sudo ip link add h5-ns type veth peer name h5-sw
sudo ip link set netns h5 h5-ns
sudo ip netns exec h5 ip addr add 10.10.10.5/24 dev h5-ns
sudo ip netns exec h5 ifconfig h5-ns up
sudo ovs-vsctl add-port of-switch-3 h5-sw
sudo ovs-vsctl set Interface h5-sw ofport_request=5
sudo ifconfig h5-sw up

echo "creating h6 namespace with ip 10.10.10.6/24 and OF_PORT=5 on of-switch-3"
sudo ip netns add h6
sudo ip link add h6-ns type veth peer name h6-sw
sudo ip link set netns h6 h6-ns
sudo ip netns exec h6 ip addr add 10.10.10.6/24 dev h6-ns
sudo ip netns exec h6 ifconfig h6-ns up
sudo ovs-vsctl add-port of-switch-3 h6-sw
sudo ovs-vsctl set Interface h6-sw ofport_request=6
sudo ifconfig h6-sw up

echo "changing BRIDGE_GROUP_ADDRESS in ryu.lib.bpdu to 01:80:c2:00:00:0e"
sudo sed -i "s/BRIDGE_GROUP_ADDRESS = '01:80:c2:00:00:00'/BRIDGE_GROUP_ADDRESS = '01:80:c2:00:00:0e'/g" /usr/local/lib/python3.6/site-packages/ryu/lib/packet/bpdu.py
