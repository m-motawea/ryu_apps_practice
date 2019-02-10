#!/bin/bash

ns_array=(h1 h2)
if_array=(h1-ns h2-ns)
br_array=(of-switch)


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

