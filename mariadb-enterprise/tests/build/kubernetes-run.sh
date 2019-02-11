#!/bin/bash
# escape image name for sed
img=$( echo "$2" | sed -e 's/\//\\\//g' - )

# delete existing resource (if any)
kubectl delete job $1-sanity 2> /dev/null

# create new resource
set -e
sed -e "s/\$(MARIADB_CLUSTER)/$1/g" -e "s/\$(IMAGE)/${img}/g" build/test-job.yaml | kubectl create -f -
# kubectl wait --for=condition=complete job/$1-sanity
