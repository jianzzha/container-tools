### setup cnv
cat <<EOF | oc create -f -
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-cnv
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-cnv-operatorgroup
  namespace: openshift-cnv 
spec:
  targetNamespaces:
  - openshift-cnv
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-cnv-subscription
  namespace: openshift-cnv
spec:
  channel: "2.3"
  name: kubevirt-hyperconverged  
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

cat <<EOF | oc create -f -
apiVersion: hco.kubevirt.io/v1alpha1
kind: HyperConverged
metadata:
  finalizers:
  - hyperconvergeds.hco.kubevirt.io
  name: kubevirt-hyperconverged
  namespace: openshift-cnv
spec:
  BareMetalPlatform: true
EOF

### start performance addon operator
cat <<EOF | oc create -f -
apiVersion: v1
kind: Namespace
metadata:
  labels:
    openshift.io/cluster-monitoring: "true"
  name: openshift-performance-addon
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-performance-addon-operatorgroup
  namespace: openshift-performance-addon
spec:
  targetNamespaces:
  - openshift-performance-addon
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: performance-addon-operator-subscription
  namespace: openshift-performance-addon
spec:
  channel: "4.4"
  name: performance-addon-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

### apply performance profile
oc label --overwrite node perf150 node-role.kubernetes.io/worker-sriov=""
cat <<EOF | oc create -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  name: worker-cnf
  namespace: openshift-machine-config-operator
  labels:
    machineconfiguration.openshift.io/role: worker-cnf
spec:
  paused: false 
  machineConfigSelector:
    matchExpressions:
      - key: machineconfiguration.openshift.io/role
        operator: In
        values: [worker,worker-sriov]
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/worker-sriov: ""
EOF

### wait until the node setup complete

### start sriov operator
cat <<EOF | oc create -f -
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-sriov-network-operator
  labels:
    openshift.io/run-level: "1"
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: sriov-network-operators
  namespace: openshift-sriov-network-operator
spec:
  targetNamespaces:
  - openshift-sriov-network-operator
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: sriov-network-operator-subsription
  namespace: openshift-sriov-network-operator
spec:
  channel: "4.4"
  name: sriov-network-operator
  source: redhat-operators 
  sourceNamespace: openshift-marketplace
EOF

### apply the sriov policy and network
cat <<EOF | oc create -f -
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetworkNodePolicy
metadata:
  name: policy-intel-east
  namespace: openshift-sriov-network-operator
spec:
  deviceType: vfio-pci
  mtu: 9000
  nicSelector:
    deviceID: "1583"
    rootDevices:
    - "0000:81:00.1"
    vendor: "8086"
    pfNames:
    - ens1f1
  nodeSelector:
    feature.node.kubernetes.io/network-sriov.capable: "true"
  numVfs: 6
  priority: 5
  resourceName: intelnics1
EOF

cat <<EOF | oc create -f -
kind: SriovNetworkNodePolicy
metadata:
  name: policy-intel-west
  namespace: openshift-sriov-network-operator
spec:
  deviceType: vfio-pci 
  mtu: 9000
  nicSelector:
    deviceID: "1583"
    rootDevices:
    - "0000:81:00.0"
    vendor: "8086"
    pfNames:
    - ens1f0
  nodeSelector:
    feature.node.kubernetes.io/network-sriov.capable: "true"
  numVfs: 6
  priority: 5
  resourceName: intelnics0
EOF

cat <<EOF | oc create -f -
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetwork
metadata:
  name: sriov-intel-east
  namespace: openshift-sriov-network-operator
spec:
  ipam: |
    {
      "type": "host-local",
      "subnet": "10.56.218.0/24",
      "rangeStart": "10.56.218.171",
      "rangeEnd": "10.56.218.181"
    }
  spoofChk: "off"
  trust: "on"
  resourceName: intelnics1
  networkNamespace: default
EOF

cat <<EOF | oc create -f -
kind: SriovNetwork
metadata:
  name: sriov-intel-west
  namespace: openshift-sriov-network-operator
spec:
  ipam: |
    {
      "type": "host-local",
      "subnet": "10.56.217.0/24",
      "rangeStart": "10.56.217.171",
      "rangeEnd": "10.56.217.181",
      "routes": [{
        "dst": "0.0.0.0/0"
      }],
      "gateway": "10.56.217.1"
    }
  spoofChk: "off"
  trust: "on"
  resourceName: intelnics0
  networkNamespace: default
EOF

### update image and push it to docker repo
ssh core@perf150 "sudo mkdir -p /var/tmp/cnv"
wget https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-2003.qcow2
LIBGUESTFS_BACKEND=direct virt-customize -a CentOS-7-x86_64-GenericCloud-2003.qcow2 --root-password password:redhat

cat <<EOF > Dockerfile
FROM scratch
ADD CentOS-7-x86_64-GenericCloud-2003.qcow2 /disk/
EOF

podman build -t docker.io/cscojianzhan/centos-vmi .
podman login
podman push docker.io/cscojianzhan/centos-vmi

### start VM using centos image with sriov interfaces
cat <<EOF | oc create -f - 
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  creationTimestamp: null
  name: vm-centos
  #annotations:
  #  k8s.v1.cni.cncf.io/networks:sriov-intel-east,sriov-intel-west
spec:
  running: true
  template:
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          interfaces:
          - masquerade: {}
            name: default
          - sriov: {}
            name: sriov-intel-east
          - sriov: {}
            name: sriov-intel-west 
        machine:
          type: ""
        resources:
          requests:
            memory: 8Gi 
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: docker.io/cscojianzhan/centos-vmi
        name: containerdisk 
      networks:
        - name: default
          pod: {}
        - multus:
            networkName: default/sriov-intel-east
          name: sriov-intel-east
        - multus:
            networkName: default/sriov-intel-west
          name: sriov-intel-west
EOF

### access VM console
subscription-manager repos --enable cnv-2.1-for-rhel-8-x86_64-rpms
dnf install kubevirt-virtctl -y
virtctl console vm-centos

