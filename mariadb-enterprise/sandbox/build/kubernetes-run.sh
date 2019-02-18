#!/bin/bash
# escape image name for sed
RAM=$4
RAM=${RAM:-2G}
img=$( echo "$2" | sed 's/\//\\\//g' )
RELEASE_NAME=$1

cleanupZeppelin(){
    kubectl delete statefulsets ${RELEASE_NAME}-mdb-zepp
    kubectl delete pvc notebook-${RELEASE_NAME}-mdb-zepp-0 --grace-period=0
    kubectl delete svc zeppelin-sandbox
}
cleanupZeppelin

if [[ "$3" == "sandbox" ]]; then
    POD_NAME="${RELEASE_NAME}-sandbox-zeppelin"
	SERVICE_NAME="${RELEASE_NAME}-mdb-zeppelin"
    DATABASE_SERVICE="${RELEASE_NAME}-mdb-cs-um-module-0.${RELEASE_NAME}-mdb-clust"
    ZEPPELIN_CONTAINER_NAME="${RELEASE_NAME}-mdb-zepp-0"
else
    echo "Invalid resource $3"
    exit 1
fi
#trap cleanupZeppelin EXIT
# delete existing resource (if any)
if kubectl delete svc "${SERVICE_NAME}" 2> /dev/null; then
    while kubectl svc pods "${SERVICE_NAME}" >/dev/null 2>/dev/null; do
        echo -n "."
        sleep 1 
    done
    echo ""
fi


if kubectl delete pod "${POD_NAME}" 2> /dev/null; then
    while kubectl get pods "${POD_NAME}" >/dev/null 2>/dev/null; do
        echo -n "."
        sleep 1 
    done
    echo ""
fi


#Get Columnstore is needed for API connectors demo
kubectl cp ${RELEASE_NAME}-mdb-cs-um-module-0:/usr/local/mariadb/columnstore/etc/Columnstore.xml ./Columnstore.xml

# create new resource
set -e
TEMPDIR=$(mktemp -d) 

if [[ "$3" == "sandbox" ]]; then
    cp -r "build/sandbox-job.yaml" "$TEMPDIR"
    sed -e "s/\$(MARIADB_CLUSTER)/${RELEASE_NAME}/g" \
        -e "s/\$(IMAGE)/${img}/g" \
        -e "s/\$(DATABASE_SERVICE)/$DATABASE_SERVICE/g" \
        -e "s/\$(RAM)/4G/g" \
        -i '' "$TEMPDIR/sandbox-job.yaml"
    cat "$TEMPDIR/sandbox-job.yaml" > build/last.yaml
    kubectl create -f "$TEMPDIR/sandbox-job.yaml"
    kubectl expose service ${RELEASE_NAME}-mdb-zeppelin --type=LoadBalancer --name=zeppelin-sandbox
else
    echo "Invalid resource $3"
    exit 1
fi
echo "Waiting for ${ZEPPELIN_CONTAINER_NAME}"
while ! kubectl get pods "${ZEPPELIN_CONTAINER_NAME}" | grep Running > /dev/null 2>/dev/null; do
    echo -n "."
    sleep 2 
done
echo "${ZEPPELIN_CONTAINER_NAME} created."
kubectl cp ./Columnstore.xml ${ZEPPELIN_CONTAINER_NAME}:/usr/local/mariadb/columnstore/etc