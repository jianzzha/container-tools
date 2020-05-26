#!/bin/bash

# env vars:
#	mode (default manual)
# additional env for master:
#       uperfSlave (slave address)
#       writeSize (write size to slave, default 8192)
#       readSize (read size from slave, default 8192)
#       duration (default 66s)

source common-libs/functions.sh

function sigfunc() {
	exit 0
}

mode=${mode:-manual}
echo "############# dumping env ###########"
env
echo "#####################################"

for cmd in uperf; do
    command -v $cmd >/dev/null 2>&1 || { echo >&2 "$cmd required but not installed.  Aborting"; exit 1; }
done

trap sigfunc TERM INT SIGUSR1

if [[ "${mode}" == "manual" ]]; then
	sleep infinity	
elif [[ "${mode}" == "slave" ]]; then
	uperf -s
elif [[ "${mode}" == "master" ]]; then
	if [[ "${uperfSlave:-undefined}" == "undefined" ]]; then
		echo "env var: uperfSlave needs to be defined for uperf master"
	else
		export uperfSlave=${uperfSlave}
		export writeSize=${writeSize:-8192}
		export readSize=${readSize:-8192}
		export duration=${duration:-66s}
		cat <<EOF >request-response.xml
<?xml version="1.0"?>
<profile name="tcp-rr-8192B-8i">
  <group nthreads="8">
    <transaction iterations="1">
      <flowop type="connect" options="remotehost=${uperfSlave} protocol=tcp tcp_nodelay"/>
    </transaction>
    <transaction duration="${duration}">
      <flowop type="write" options="size=${writeSize}"/>
      <flowop type="read"  options="size=${readSize}"/>
    <transaction iterations="1">
      <flowop type="disconnect" />
    </transaction>
  </group>
</profile>
EOF
		uperf  -m request-response.xml
	fi
	sleep infinity	
fi
