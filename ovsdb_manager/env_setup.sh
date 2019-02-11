#!/bin/bash

set -e


echo "configuring OVSDB manager"
sudo ovs-vsctl set-manager "tcp:127.0.0.1:6640"

echo "creating h1 namespace with ip 10.10.10.1/24"
sudo ip netns add h1
sudo ip link add h1-ns type veth peer name h1-sw
sudo ip link set netns h1 h1-ns
sudo ip netns exec h1 ip addr add 10.10.10.1/24 dev h1-ns
sudo ip netns exec h1 ifconfig h1-ns up
sudo ifconfig h1-sw up

echo "creating h2 namespace with ip 10.10.10.2/24"
sudo ip netns add h2
sudo ip link add h2-ns type veth peer name h2-sw
sudo ip link set netns h2 h2-ns
sudo ip netns exec h2 ip addr add 10.10.10.2/24 dev h2-ns
sudo ip netns exec h2 ifconfig h2-ns up
sudo ifconfig h2-sw up
