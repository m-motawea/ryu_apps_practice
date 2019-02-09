#!/bin/bash

set -e

echo "enabling ip forwarding"
sudo sh -c "echo '1' > /proc/sys/net/ipv4/ip_forward"

echo "creating of-switch (OVS Bridge) as pure OpenFlow1.3 switch"
sudo ovs-vsctl add-br of-switch
sudo ovs-vsctl set bridge of-switch protocols=OpenFlow13
sudo ovs-vsctl set bridge of-switch other-config:datapath_id=0000000000000001
sudo ovs-ofctl -O OpenFlow13 del-flows of-switch
sudo ovs-vsctl set-controller of-switch tcp:127.0.0.1:6633

echo "loading bonding kernel module"
sudo sh -c "echo 'alias bond0 bonding' > /etc/modprobe.d/bonding.conf"
sudo sh -c "echo 'options bonding mode=4' >> /etc/modprobe.d/bonding.conf"
sudo modprobe bonding

echo "creating h1 namespace with ip 10.10.10.1/24 with bonded link OF_PORTS=1,3"
sudo ip netns add h1
sudo ip link add h1-ns1 type veth peer name h1-sw1
sudo ip link add h1-ns2 type veth peer name h1-sw2
sudo ip link set netns h1 h1-ns1
sudo ip link set netns h1 h1-ns2

sudo ip netns exec h1 ip link add bond0 type bond
sudo ip netns exec h1 ip link set h1-ns1 down
sudo ip netns exec h1 ip link set h1-ns2 down
sudo ip netns exec h1 ip link set h1-ns1 master bond0
sudo ip netns exec h1 ip link set h1-ns2 master bond0
sudo ip netns exec h1 ip addr add 10.10.10.1/24 dev bond0
sudo ip netns exec h1 ip link set bond0 up

sudo ovs-vsctl add-port of-switch h1-sw1
sudo ovs-vsctl add-port of-switch h1-sw2
sudo ovs-vsctl set Interface h1-sw1 ofport_request=1
sudo ovs-vsctl set Interface h1-sw2 ofport_request=3
sudo ifconfig h1-sw1 up
sudo ifconfig h1-sw2 up

echo "creating h2 namespace with ip 10.10.10.2/24 and OF_PORT=2"
sudo ip netns add h2
sudo ip link add h2-ns type veth peer name h2-sw
sudo ip link set netns h2 h2-ns
sudo ip netns exec h2 ip addr add 10.10.10.2/24 dev h2-ns
sudo ip netns exec h2 ifconfig h2-ns up
sudo ovs-vsctl add-port of-switch h2-sw
sudo ovs-vsctl set Interface h2-sw ofport_request=2
sudo ifconfig h2-sw up