###### no container work; all commands on host
export PATH=$PATH:/usr/local/share/openvswitch/scripts
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock
ovs-ctl --no-ovs-vswitchd --system-id=random start
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024,1024"
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-lcore-mask=0x10000
ovs-vsctl --no-wait set Open_vSwitch . other_config:pmd-cpu-mask=0xfe0000
setenforce permissive
ovs-ctl --no-ovsdb-server --db-sock="$DB_SOCK" start
ovs-vsctl add-br br0 -- set bridge br0 datapath_type=netdev
dpdk-devbind -u 0000:81:00.0 0000:81:00.1
dpdk-devbind -b vfio-pci 0000:81:00.0 0000:81:00.1
ovs-vsctl add-port br0 p2p1 -- set Interface p2p1 type=dpdk options:dpdk-devargs=0000:81:00.0
ovs-vsctl add-port br0 p2p2 -- set Interface p2p2 type=dpdk options:dpdk-devargs=0000:81:00.1

