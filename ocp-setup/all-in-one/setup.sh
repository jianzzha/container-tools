#!/usr/bin/bash

oc label --overwrite node worker0 node-role.kubernetes.io/worker-cnf=""
oc label --overwrite node worker0 feature.node.kubernetes.io/network-sriov.capable=true

oc create -f perf-sub.yaml

while ! oc get pods -n openshift-performance-addon | grep Running; do
    sleep 5
done

oc create -f machine_config_pool.yaml
oc create -f performance_profile.yaml

status=$(oc get mcp | awk '/worker-cnf/{print $4}')
while [ $status != False ]; do 
    sleep 5
    status=$(oc get mcp | awk '/worker-cnf/{print $4}')
done

oc create -f sriov-sub.yaml

while ! oc get pods -n openshift-sriov-network-operator | grep Running; do
    sleep 5
done

oc create -f sriov-nic-policy.yaml

oc create -f sriov-network.yaml

oc create -f service.yaml

