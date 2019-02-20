#!/bin/bash

br_array=(of-switch-1 of-switch-2 of-switch-3)



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
