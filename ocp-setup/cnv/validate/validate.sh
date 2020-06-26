#!/usr/bin/bash

set -xeuo pipefail


function cleanup {
    podman rmi docker.io/cscojianzhan/cirros-vmi 2>/dev/null || true
    /bin/rm -f Dockerfile 2>/dev/null || true
    oc delete svc myvm 2>/dev/null || true
    oc delete pod vm-client 2>/dev/null || true
    oc delete vm vm-cirros 2>/dev/null || true
} 

trap cleanup ERR SIGINT
    
function test_result {
    echo $1:$2
    if [[ "$2" == "failed" ]]; then
        cleanup
        exit 0
    fi
}

# start from clean state
cleanup

if ! command -v podman >/dev/null 2>&1; then
    test_result podman_command failed
fi

if ! podman pull docker.io/cscojianzhan/cirros-vmi; then
cat <<EOF > Dockerfile
FROM scratch
ADD  cirros-0.5.1-x86_64-disk.img /disk/
EOF

    if [ ! -f cirros-0.5.1-x86_64-disk.img ]; then
        curl -L -o cirros-0.5.1-x86_64-disk.img http://download.cirros-cloud.net/0.5.1/cirros-0.5.1-x86_64-disk.img
        if [ ! -f cirros-0.5.1-x86_64-disk.img ]; then
             test_result failed
        fi
    fi
    podman build -t docker.io/cscojianzhan/cirros-vmi . && podman push docker.io/cscojianzhan/cirros-vmi && /bin/rm -f Dockerfile
    if [[ "$?" != "0" ]]; then
        test_result podman_build failed
    fi
fi

if ! command -v virtctl >/dev/null 2>&1; then
    export KUBEVIRT_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases | grep tag_name | grep -v -- - | sort -V | tail -1 | awk -F':' '{print $2}' | sed 's/,//' | xargs)
    sudo curl -L -o /usr/local/bin/virtctl \
          https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/virtctl-${KUBEVIRT_VERSION}-linux-amd64
    if [ ! -f /usr/local/bin/virtctl ]; then
        test_result virtctl_install failed
    fi
    sudo chmod 0755 /usr/local/bin/virtctl 
fi

oc create -f cirros.yaml
count=100
while ((count-- > 0)); do
        status=$(oc get vmi vm-cirros -o json | jq -r '.status.phase' 2>/dev/null || true)
        if [[ "${status}" == "Running" ]]; then
                break
        fi
        sleep 3s
done

oc create -f client.yaml
count=100
while ((count-- > 0)); do
        status=$(oc get pod vm-client -o json | jq -r '.status.phase' 2>/dev/null || true)
        if [[ "${status}" == "Running" ]]; then 
                break
        fi
        sleep 3s
done

export vmip=$(oc get vmi vm-cirros -o json | jq -r '.status.interfaces[0].ipAddress')
count=100
while ((count-- > 0)); do
    retcode=$(oc exec -it vm-client -- sh -c "nc -z ${vmip} 22; echo \$?")
    if [[ "${retcode}" =~ "0" ]]; then
        break
    fi
    sleep 3s
done
         
if [[ "${retcode}" =~ "0" ]]; then
    test_result pod_ssh_vm pass
else
    test_result pod_ssh_vm failed
fi

if ! virtctl expose virtualmachine vm-cirros --name myvm --type NodePort --port 22 --target-port 22; then
    test_result vm_service failed
fi

export svcip=$(oc get svc myvm -o json | jq .spec.clusterIP)
export svcport=$(oc get svc myvm -o json | jq .spec.ports[0].nodePort)
retcode=$(oc exec -it vm-client -- sh -c "nc -z ${svcip} ${svcport}; echo \$?")
if [[ "${retcode}" =~ "0" ]]; then
    test_result vm_svc pass
else
    test_result vm_svc failed
fi

cleanup
