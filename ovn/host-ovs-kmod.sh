#/bin/sh
set -o pipefail -e

OVSDIR=/tmp/ovs

if command -v rpm >/dev/null 2>&1; then
	yum install -y openssl-devl
	yum install -y @'Development Tools'
else
	apt install -y libssl-dev
fi
git clone https://github.com/openvswitch/ovs.git ${OVSDIR}
pushd ${OVSDIR}
./boot.sh
./configure --enable-ssl --with-linux=/lib/modules/$(uname -r)/build
make && make modules_install
popd
