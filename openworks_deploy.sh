#!/bin/bash
K8S_NAMESPACE=buff-dbaas
MAIN_DIRECTORY=$(pwd)
RELEASE_NAME=$1
CLEANUP=$2
CLEANUP=${CLEANUP:-boza}
topology=columnstore
CS_INIT_FLAG=/usr/local/mariadb/columnstore/etc/container-initialized

cleanup(){
    echo "Cleanup ..."
    helm del --purge ${RELEASE_NAME}
}

deleteObjects(){
    kubectl delete svc ${RELEASE_NAME}-mariadb --namespace=${K8S_NAMESPACE} --grace-period=0
    kubectl delete daemonsets,replicasets,services,deployments,pods,rc,secrets,pvc,statefulsets mariadb=${RELEASE_NAME} --namespace=${K8S_NAMESPACE} --grace-period=0
    kubectl delete daemonsets,replicasets,services,deployments,pods,rc,secrets,pvc,statefulsets mariadb-zeppelin=${RELEASE_NAME} --namespace=${K8S_NAMESPACE} --grace-period=0
    kubectl delete pvc -l mariadb=${RELEASE_NAME} --namespace=${K8S_NAMESPACE} --grace-period=0
    kubectl delete pvc -l um.mariadb=${RELEASE_NAME} --namespace=${K8S_NAMESPACE} --grace-period=0
    kubectl delete pvc -l pm.mariadb=${RELEASE_NAME} --namespace=${K8S_NAMESPACE} --grace-period=0
    kubectl delete pvc -l columnstore.mariadb=${RELEASE_NAME} --namespace=${K8S_NAMESPACE} --grace-period=0
}

cleanNamespace(){
    kubectl delete daemonsets,replicasets,services,deployments,pods,rc,secrets,pvc,statefulsets --all --namespace=${K8S_NAMESPACE} --grace-period=0
}

cleanupZeppelin(){
    kubectl delete svc ${RELEASE_NAME}-mdb-zeppelin --namespace=${K8S_NAMESPACE}
    kubectl delete pod ${RELEASE_NAME}-mdb-zepp-0 --namespace=${K8S_NAMESPACE}
    kubectl delete statefulsets ${RELEASE_NAME}-mdb-zepp --namespace=${K8S_NAMESPACE}
    kubectl delete svc zeppelin-sandbox --namespace=${K8S_NAMESPACE}
    kubectl delete pvc notebook-${RELEASE_NAME}-mdb-zepp-0 --grace-period=0 --namespace=${K8S_NAMESPACE}
}

if [ $CLEANUP = 'cleanup' ]; then
    cleanup
    cleanupZeppelin
    deleteObjects
    cleanNamespace
fi
if [ $CLEANUP = 'namespace' ]; then
    cleanNamespace
fi

set -e
echo "Helm install chart"
helm install ./mariadb-enterprise  \
--name ${RELEASE_NAME} --set mariadb.cluster.topology=$topology \
--set ID=1 \
--set mariadb.columnstore.sandbox=true \
--set mariadb.columnstore.test=true \
--set mariadb.server.resources.requests.memory=1G \
--set mariadb.debug=false \
--namespace=${K8S_NAMESPACE} 

echo "Waiting for ${RELEASE_NAME}-mdb-cs-um-module-0"
while ! kubectl get pods ${RELEASE_NAME}-mdb-cs-um-module-0 | grep Running > /dev/null 2>/dev/null; do
    echo -n "."
    sleep 2 
done
ATTEMPT=0
while ( ! $(kubectl exec ${RELEASE_NAME}-mdb-cs-um-module-0 -- test -f "$CS_INIT_FLAG" > /dev/null 2>/dev/null ) ) && [ $ATTEMPT -le 60 ]; do
    echo -ne "-"
    sleep 5
    ATTEMPT=$(($ATTEMPT+1))
done

cd mariadb-enterprise/sandbox
make sandbox MARIADB_CLUSTER=${RELEASE_NAME} 
cd $MAIN_DIRECTORY
