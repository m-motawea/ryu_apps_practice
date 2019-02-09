#!/bin/bash

set -e

echo "enabling ip forwarding"
sudo sh -c "echo '1' > /proc/sys/net/ipv4/ip_forward"

echo "creating of-switch-1 (OVS Bridge) as pure OpenFlow1.3 switch"
sudo ovs-vsctl add-br of-switch-1
sudo ovs-vsctl set bridge of-switch-1 protocols=OpenFlow13
sudo ovs-ofctl -O OpenFlow13 del-flows of-switch-1
sudo ovs-vsctl set-controller of-switch-1 tcp:127.0.0.1:6633

echo "creating of-switch-2 (OVS Bridge) as pure OpenFlow1.3 switch"
sudo ovs-vsctl add-br of-switch-2
sudo ovs-vsctl set bridge of-switch-2 protocols=OpenFlow13
sudo ovs-ofctl -O OpenFlow13 del-flows of-switch-2
sudo ovs-vsctl set-controller of-switch-2 tcp:127.0.0.1:6633

echo "linking (of-switch-1 & of-switch-2) with patch ports"

echo "creating patch port in of-switch-1"
sudo ovs-vsctl add-port of-switch-1 p1-sw1
sudo ovs-vsctl set Interface p1-sw1 ofport_request=10
sudo ovs-vsctl set Interface p1-sw1 type=patch
sudo ovs-vsctl set Interface p1-sw1 options:peer=p1-sw2

echo "creating patch port in of-switch-2"
sudo ovs-vsctl add-port of-switch-2 p1-sw2
sudo ovs-vsctl set Interface p1-sw2 ofport_request=10
sudo ovs-vsctl set Interface p1-sw2 type=patch
sudo ovs-vsctl set Interface p1-sw2 options:peer=p1-sw1

echo "creating h1 namespace with ip 10.10.10.1/24 and OF_PORT=1"
sudo ip netns add h1
sudo ip link add h1-ns type veth peer name h1-sw
sudo ip link set netns h1 h1-ns
sudo ip netns exec h1 ip addr add 10.10.10.1/24 dev h1-ns
sudo ip netns exec h1 ifconfig h1-ns up
sudo ovs-vsctl add-port of-switch-1 h1-sw
sudo ovs-vsctl set Interface h1-sw ofport_request=1
sudo ifconfig h1-sw up

echo "creating h2 namespace with ip 10.10.10.2/24 and OF_PORT=2"
sudo ip netns add h2
sudo ip link add h2-ns type veth peer name h2-sw
sudo ip link set netns h2 h2-ns
sudo ip netns exec h2 ip addr add 10.10.10.2/24 dev h2-ns
sudo ip netns exec h2 ifconfig h2-ns up
sudo ovs-vsctl add-port of-switch-1 h2-sw
sudo ovs-vsctl set Interface h2-sw ofport_request=2
sudo ifconfig h2-sw up

echo "creating h3 namespace with ip 10.10.10.3/24 and OF_PORT=3"
sudo ip netns add h3
sudo ip link add h3-ns type veth peer name h3-sw
sudo ip link set netns h3 h3-ns
sudo ip netns exec h3 ip addr add 10.10.10.3/24 dev h3-ns
sudo ip netns exec h3 ifconfig h3-ns up
sudo ovs-vsctl add-port of-switch-2 h3-sw
sudo ovs-vsctl set Interface h3-sw ofport_request=3
sudo ifconfig h3-sw up

echo "creating h4 namespace with ip 10.10.10.4/24 and OF_PORT=4"
sudo ip netns add h4
sudo ip link add h4-ns type veth peer name h4-sw
sudo ip link set netns h4 h4-ns
sudo ip netns exec h4 ip addr add 10.10.10.4/24 dev h4-ns
sudo ip netns exec h4 ifconfig h4-ns up
sudo ovs-vsctl add-port of-switch-2 h4-sw
sudo ovs-vsctl set Interface h4-sw ofport_request=4
sudo ifconfig h4-sw up