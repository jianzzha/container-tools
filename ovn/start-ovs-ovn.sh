#/bin/sh
ovn-ctl start_northd
sleep 1
ovs-ctl start --external-id="system-id=test" --external-id="ovn-remote=unix:/usr/local/var/run/ovn/ovnsb_db.sock" --external-id="ovn-encap-ip=127.0.0.1" --external-id="ovn-encap-type=geneve" --system-id=test
sleep 1
ovn-ctl start_controller
sleep infinity
