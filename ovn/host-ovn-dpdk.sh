###### on host
setenforce permissive
export PATH=$PATH:/usr/local/share/openvswitch/scripts
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock
ovs-ctl --no-ovs-vswitchd --system-id=random start
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024,1024"
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-lcore-mask=0x10000
ovs-vsctl --no-wait set Open_vSwitch . other_config:pmd-cpu-mask=0xfe0000
ovs-ctl --no-ovsdb-server --db-sock="$DB_SOCK" start
ovs-vsctl set open . external-id:ovn-remote="unix:/usr/local/var/run/ovn/ovnsb_db.sock"
ovs-vsctl set open . external-id:ovn-encap-type=geneve
ovs-vsctl set open . external-id:ovn-encap-ip=127.0.0.1
ovs-vsctl set open . external-id:system-id=test

docker run --rm -it --privileged --net=host -v /usr/local/var/run/openvswitch:/usr/local/var/run/openvswitch ovn-image sh

###### inside container
ovn-ctl start_northd
ovn-ctl start_controller
ovn-nbctl ls-add sw0
ovn-nbctl lsp-add sw0 sw0-port1
ovn-nbctl lsp-add sw0 sw0-port2
ovn-nbctl lsp-set-addresses sw0-port1 3c:fd:fe:b8:99:a5
ovn-nbctl lsp-set-addresses sw0-port2 3c:fd:fe:b8:99:a4

###### on host
ovs-vsctl set bridge br-int datapath_type=netdev
dpdk-devbind -u 0000:81:00.0 0000:81:00.1
dpdk-devbind -b vfio-pci 0000:81:00.0 0000:81:00.1
ovs-vsctl add-port br-int p2p1 --  set Interface p2p1 external_ids:iface-id=sw0-port1 type=dpdk options:dpdk-devargs=0000:81:00.0
ovs-vsctl add-port br-int p2p2 --  set Interface p2p2 external_ids:iface-id=sw0-port2 type=dpdk options:dpdk-devargs=0000:81:00.1
