# ryu_apps_practice
applications in ryubook with scripts to prepare the environment

### Requirements:
1- Open vSwitch ($ dnf install openvswitch -y)

2- python3.6

3- ryu ($ pip3.6 install ryu)

### Run:
1- Setup your environment using ($ sudo ./env_setup.sh).
This will create and configure ovs bridges to connect to controller tcp:127.0.0.1:6633.
It will also create net-namespaces as hosts.

2- Execute the app using ($ ryu-manager --verbose app_name.py).
Execute ($ sudo ip netns exec h1 bash) to use a host shell.

3- Clean you environment using ($ sudo ./env_destory.sh).
This will remove all configuration done by env_setup.sh
