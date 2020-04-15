#/bin/sh
ovn-ctl start_northd
sleep 1
###### inside container
ovs-ctl start --external-id="system-id=test" --external-id="ovn-remote=unix:/usr/local/var/run/ovn/ovnsb_db.sock" --external-id="ovn-encap-ip=127.0.0.1" --external-id="ovn-encap-type=geneve" --system-id=random
##### or on host
ovs-vsctl set open . external-id:ovn-remote="unix:/usr/local/var/run/ovn/ovnsb_db.sock"
ovs-vsctl set open . external-id:ovn-encap-type=geneve
ovs-vsctl set open . external-id:ovn-encap-ip=127.0.0.1
ovs-vsctl set open . external-id:system-id=test

sleep 1
ovn-ctl start_controller
sleep infinity
