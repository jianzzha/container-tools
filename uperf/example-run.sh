#!/bin/bash - 
#===============================================================================
#
#          FILE: example-run.sh
# 
#         USAGE: ./example-run.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Jianzhu Zhang (), jianzzha@redhat.com
#       CREATED: 05/22/2020 03:27:08 PM
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
#!/usr/bin/bash
oc create -f pod-uperf-slave.yaml
while true; do
	status=$(oc get pods uperf-slave -o json | jq -r '.status.phase')
	if [[ "${status}" == "Running" ]]; then
		break
	fi
	sleep 5s
done
export slave=$(oc get pods uperf-slave -o json | jq -r '.status.podIP')
envsubst < pod-uperf-master.yaml | oc create -f -


