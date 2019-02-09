#!/bin/bash

ns_array=(h1 h2 h3 h4 h5 h6)
if_array=(h1-ns h2-ns h3-ns h4-ns h5-ns h6-ns s1-s2 s1-s3 s2-s3)
br_array=(of-switch-1 of-switch-2 of-switch-3)


echo "cleaning network namespaces..."
for ns in ${ns_array[@]}
do
  echo "deleting namespace ${ns}..."
  sudo ip netns del ${ns}
  echo "${ns} namespace deleted."
done
echo "finished cleaning network namespaces."


echo "cleaning OVS bridges..."
for br in ${br_array[@]}
do
  echo "cleaning bridge ${br} ports..."
  port_array=( $(sudo ovs-vsctl list-ifaces ${br}) )
  for port in ${port_array[@]}
  do
    echo "deleting port ${port}..."
    sudo ovs-vsctl del-port ${port}
    echo "port ${port} deleted."
  done
  echo "deleting bridge ${br}..."
  sudo ovs-vsctl del-br ${br}
  echo "bridge ${br} deleted."
done
echo "finished cleaning OVS-bridges."


echo "cleaning ifaces..."
for iface in ${if_array[@]}
do
  echo "deleteing iface ${iface}..."
  sudo ip link delete ${iface}
  echo "iface ${iface} deleted."
done
echo "finished cleaning ifaces."

echo "changing BRIDGE_GROUP_ADDRESS in ryu.lib.bpdu back to 01:80:c2:00:00:00"
sudo sed -i "s/BRIDGE_GROUP_ADDRESS = '01:80:c2:00:00:0e'/BRIDGE_GROUP_ADDRESS = '01:80:c2:00:00:00'/g" /usr/local/lib/python3.6/site-packages/ryu/lib/packet/bpdu.py