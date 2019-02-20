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


echo "linking (of-switch-1 & of-switch-2) with patch ports and OF_PORT=10"

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

echo "linking (of-switch-1 & of-switch-3) with patch ports and OF_PORT=20"

echo "creating patch port in of-switch-1"
sudo ovs-vsctl add-port of-switch-1 p2-sw1
sudo ovs-vsctl set Interface p2-sw1 ofport_request=20
sudo ovs-vsctl set Interface p2-sw1 type=patch
sudo ovs-vsctl set Interface p2-sw1 options:peer=p2-sw3
echo "creating patch port in of-switch-3"
sudo ovs-vsctl add-port of-switch-3 p2-sw3
sudo ovs-vsctl set Interface p2-sw3 ofport_request=20
sudo ovs-vsctl set Interface p2-sw3 type=patch
sudo ovs-vsctl set Interface p2-sw3 options:peer=p2-sw1

echo "linking (of-switch-2 & of-switch-3) with patch ports and OF_PORT=30"

echo "creating patch port in of-switch-3"
sudo ovs-vsctl add-port of-switch-3 p3-sw3
sudo ovs-vsctl set Interface p3-sw3 ofport_request=30
sudo ovs-vsctl set Interface p3-sw3 type=patch
sudo ovs-vsctl set Interface p3-sw3 options:peer=p3-sw2
echo "creating patch port in of-switch-2"
sudo ovs-vsctl add-port of-switch-2 p3-sw2
sudo ovs-vsctl set Interface p3-sw2 ofport_request=30
sudo ovs-vsctl set Interface p3-sw2 type=patch
sudo ovs-vsctl set Interface p3-sw2 options:peer=p3-sw3


