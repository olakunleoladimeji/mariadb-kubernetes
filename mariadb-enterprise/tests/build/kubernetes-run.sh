#!/bin/bash
# escape image name for sed
img=$( echo "$2" | sed -e 's/\//\\\//g' - )

# delete existing resource (if any)
if kubectl delete pod $1-sanity-test 2> /dev/null; then
	while kubectl get pods $1-sanity-test >/dev/null 2>/dev/null; do
		echo -e "."
		sleep 1 
	done
	echo ""
fi

# create new resource
set -e
sed -e "s/\$(MARIADB_CLUSTER)/$1/g" -e "s/\$(IMAGE)/${img}/g" build/test-job.yaml | kubectl create -f -
# kubectl wait --for=condition=complete job/$1-sanity
