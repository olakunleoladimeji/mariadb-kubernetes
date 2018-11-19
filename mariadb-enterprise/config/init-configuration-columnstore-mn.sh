#!/bin/sh
# Copyright (C) 2018, MariaDB Corporation
#
# This script customizes templates based on the parameters passed to a command-line tool
# the path to the target directory needs to be passed as first argument



function expand_templates() {
    sed -e "s/<<MASTER_HOST>>/$MASTER_HOST/g" \
        -e "s/<<ADMIN_USERNAME>>/$ADMIN_USER/g" \
        -e "s/<<ADMIN_PASSWORD>>/$ADMIN_PWD/g" \
        -e "s/<<REPLICATION_USERNAME>>/$REPL_USER/g" \
        -e "s/<<REPLICATION_PASSWORD>>/$REPL_PWD/g" \
        -e "s/<<RELEASE_NAME>>/$RELEASE_NAME/g" \
        -e "s/<<CLUSTER_ID>>/$CLUSTER_ID/g" \
        $1
}

{{- if .Values.mariadb.debug}}
    #set +x
    echo '------------------------'
    echo 'Init CS Module Container'
    echo '------------------------'
    #set -x
{{- end }}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# APPLICATION=$(hostname -f | cut -d '.' -f 2 | cut -d '-' -f 1)
# ENVIRONMENT=$(hostname -f | cut -d '.' -f 2 | cut -d '-' -f 2)
ADMIN_USER=$(cat /mnt/secrets/admin-username)
ADMIN_PWD=$(cat /mnt/secrets/admin-password)
REPL_USER=$(cat /mnt/secrets/repl-username)
REPL_PWD=$(cat /mnt/secrets/repl-password)
DB_HOST="$(hostname -f | cut -d '.' -f 1).$(hostname -f | cut -d '.' -f 2)"
UM_COUNT={{ .Values.mariadb.columnstore.um.replicas }}
PM_COUNT={{ .Values.mariadb.columnstore.pm.replicas }}

if [[ "$MARIADB_CS_NODE" == "UM" && -f "/mnt/config-map/master" ]]; then
    export MARIADB_CS_MASTER="$(cat /mnt/config-map/master)"
fi

expand_templates /mnt/config-template/start-mariadb-instance.sh >> /mnt/config-map/start-mariadb-instance.sh

#what else can it be in this file
echo $CLUSTER_TOPOLOGY
if [[ "$CLUSTER_TOPOLOGY" == "columnstore" ]]; then
    echo "Init Columnstore"
    echo "$MARIADB_CS_NODE:$MARIADB_CS_MASTER"
    echo "Columnstore Init"
    echo "-----------------"

    if [[ "$MARIADB_CS_NODE" == "UM" && -f "/mnt/config-map/master" ]]; then
        export MARIADB_CS_MASTER="$(cat /mnt/config-map/master)"
    fi

    #Get last digit of the hostname
    MY_HOSTNAME=$(hostname)
    SPLIT_HOST=(${MY_HOSTNAME//-/ }); 
    CONT_INDEX=${SPLIT_HOST[(${#SPLIT_HOST[@]}-1)]}

    if [[ "$MARIADB_CS_NODE" == "UM" ]]; then
        if [[ "$CONT_INDEX" -eq 0 ]]; then
            #First PM
            echo "UM Master"
            expand_templates /mnt/config-template/init_um_master.sh >> /mnt/config-map/cs_init.sh
            expand_templates /mnt/config-template/init_um_master_pi.sh >> /mnt/config-map/cs_post_init.sh
{{- if .Values.mariadb.columnstore.test}}
            expand_templates /mnt/config-template/test_cs.sh >> /mnt/config-map/test_cs.sh
            expand_templates /mnt/config-template/initdb.sql >> /mnt/config-map/initdb.sql
{{- end }}
{{- if .Values.mariadb.columnstore.sandbox}}
            cp /mnt/config-template/02_load_bookstore_data.sh /docker-entrypoint-initdb.d/02_load_bookstore_data.sh
{{- end }}
            #expand_templates /mnt/config-template/custom.sh >> /docker-entrypoint-initdb.d/custom.sh
        else
            #Any PM but first
            echo "UM Slave"
            expand_templates /mnt/config-template/init_um_slave.sh >> /mnt/config-map/cs_init.sh
            expand_templates /mnt/config-template/init_um_slave_pi.sh >> /mnt/config-map/cs_post_init.sh
        fi
    elif [[ "$MARIADB_CS_NODE" == "PM" ]]; then
        #use the last PM to start initialisation
        #if [[ "$CONT_INDEX" -eq $(( PM_COUNT-1 )) ]]; then     
        if [[ "$CONT_INDEX" -eq 0 ]]; then     
            #First PM
            echo "PM1"
            expand_templates /mnt/config-template/init_pm_postconf.sh >> /mnt/config-map/cs_init.sh
        else
            #Any PM but first
            echo "PM"
            expand_templates /mnt/config-template/init_pm.sh >> /mnt/config-map/cs_init.sh
        fi
    fi
fi