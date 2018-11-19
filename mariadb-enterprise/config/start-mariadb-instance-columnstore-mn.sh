#!/usr/bin/bash
# Copyright (C) 2018, MariaDB Corporation
#
# Starts and initializes a MariaDB columnstore instance
{{- if .Values.mariadb.debug}}
    #set +x
    echo '-------------------------'
    echo 'Start CS Module Container'
    echo '-------------------------'
    #set -x
{{- end }}
#Not expanded
MASTER_HOST="<<MASTER_HOST>>"
ADMIN_USERNAME="<<ADMIN_USERNAME>>"
ADMIN_PASSWORD="<<ADMIN_PASSWORD>>"
REPLICATION_USERNAME="<<REPLICATION_USERNAME>>"
REPLICATION_PASSWORD="<<REPLICATION_PASSWORD>>"
RELEASE_NAME="<<RELEASE_NAME>>"
CLUSTER_ID="<<CLUSTER_ID>>"

{{- if .Values.mariadb.debug}}
export MARIADB_CS_DEBUG=1
{{- end }}

#TODO: Container Install 
#TODO: Move those to the container image
    #yum install -y bind-utils
#TODO: End Container Install

UM_COUNT={{ .Values.mariadb.columnstore.um.replicas }}
PM_COUNT={{ .Values.mariadb.columnstore.pm.replicas }}
function ping_hosts() { 
    CS_SERVICE="{{ .Release.Name }}-mdb-cs-service"
    UM_HOST="{{ .Release.Name }}-{{ .Values.mariadb.columnstore.um.moduleName }}-"
    PM_HOST="{{ .Release.Name }}-{{ .Values.mariadb.columnstore.pm.moduleName }}-"
    RET_CD=0
    for i in `seq 0 $(( UM_COUNT-1 ))`
    do
        ping -c 1 $UM_HOST$i.$CS_SERVICE 2>&1 >/dev/null
        if [[ $? -gt 0 ]]; then
            RET_CD=$(( RET_CD+1 ))
        fi
    done
    for i in `seq 0 $(( PM_COUNT-1 ))`
    do
        ping -c 1 $PM_HOST$i.$CS_SERVICE 2>&1 >/dev/null
        if [[ $? -gt 0 ]]; then
            RET_CD=$(( RET_CD+1 ))
        fi
    done
    return "$RET_CD"
}

function wait_ping_hosts() {
    ping_hosts
    hosts_down=$?
    while [[ $hosts_down -gt 0 ]]; do
        {{- if .Values.mariadb.debug}}
        echo "$hosts_down hosts still down. Retrying ..."
        {{- end}}
        sleep 5
        ping_hosts
        hosts_down=$?
    done
    {{- if .Values.mariadb.debug}}
    echo "All $((UM_COUNT+PM_COUNT)) hosts up ("$UM_COUNT"UM "$PM_COUNT"PM)"
    {{- end}}
}

function build_post_config_input() { 
    PREFIX="{{ .Values.mariadb.columnstore.pm.postConfigInput }}"
    CS_SERVICE="{{ .Release.Name }}-mdb-cs-service"
    UM_HOST="{{ .Release.Name }}-{{ .Values.mariadb.columnstore.um.moduleName }}-"
    PM_HOST="{{ .Release.Name }}-{{ .Values.mariadb.columnstore.pm.moduleName }}-"
    MODULES=""
    MODULES="$MODULES$UM_COUNT\n"
    for i in `seq 0 $(( UM_COUNT-1 ))`
    do
        IP=$(get_IP_from_ping $UM_HOST$i.$CS_SERVICE)
        MODULES="$MODULES$UM_HOST$i.$CS_SERVICE\n$IP\n\n"
    done
    MODULES="$MODULES$PM_COUNT\n"
    for i in `seq 0 $(( PM_COUNT-1 ))`
    do
        IP=$(get_IP_from_ping $PM_HOST$i.$CS_SERVICE)
        MODULES="$MODULES$PM_HOST$i.$CS_SERVICE\n$IP\n\n$(( i+1 ))\n"
    done
    echo "$PREFIX$MODULES"
}

function get_IP_from_ping() {
    ATTEMPT=1
    RET_IP=$(ping -q -c 1 -t 5 "$1" | grep PING | sed -e "s/).*//" | sed -e "s/.*(//")
    while [ -z "$RET_IP" ] && [ $ATTEMPT -le 5 ]; do
        PING_DEBUG="$PING_DEBUG\n-- Ping failed to resolve $ATTEMPT host ("$1")! --"
        sleep 2
        ATTEMPT=$(($ATTEMPT+1))
        RET_IP=$(ping -q -c 1 -t 5 "$1" | grep PING | sed -e "s/).*//" | sed -e "s/.*(//")
        #RET_IP=$( host $IP | sed -e "s/.*\ //" )
    done
    echo $RET_IP
}


# get server id from hostname, it will have the format <something>-<id>
[[ $(hostname) =~ -([0-9]+)$ ]] || exit 1
server_id=${BASH_REMATCH[1]}

# load backup
if [[ ! "$BACKUP_CLAIM_NAME" == "" ]]; then
    if [[ "$MASTER_HOST" == "localhost" ]]; then
        chown -R mysql:mysql /backup/$RESTORE_FROM_FOLDER
    fi
fi


if [[ "$MARIADB_CS_NODE" == "UM" && -f "/mnt/config-map/master" ]]; then
    export MARIADB_CS_MASTER="$(cat /mnt/config-map/master)"
fi

MY_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
#what else can it be in this file
echo $CLUSTER_TOPOLOGY
if [[ "$CLUSTER_TOPOLOGY" == "columnstore" ]]; then
    echo "Init Columnstore"
    echo "$MARIADB_CS_NODE:$MY_IP"
    echo "Master:$MARIADB_CS_MASTER"
    if [[ "$MARIADB_CS_NODE" == "UM" && -f "/mnt/config-map/master" ]]; then
        export MARIADB_CS_MASTER="$(cat /mnt/config-map/master)"
    fi

    #Get last digit of the hostname
    MY_HOSTNAME=$(hostname)
    SPLIT_HOST=(${MY_HOSTNAME//-/ }); 
    CONT_INDEX=${SPLIT_HOST[(${#SPLIT_HOST[@]}-1)]}
    
    if [[ "$MARIADB_CS_NODE" == "UM" ]]; then
        if [[ "$CONT_INDEX" -eq 0 ]]; then
            wait_ping_hosts
            #Init master
            echo "UM Master"
            sh /mnt/config-map/cs_init.sh 2>&1 &
            exec /usr/sbin/runsvdir-start
        else
            #Init slave
            echo "UM Slave"
            sh /mnt/config-map/cs_init.sh 2>&1 &
            exec /usr/sbin/runsvdir-start
        fi
    elif [[ "$MARIADB_CS_NODE" == "PM" ]]; then
        #if [[ "$CONT_INDEX" -eq $(( PM_COUNT-1 )) ]]; then
        if [[ "$CONT_INDEX" -eq 0 ]]; then
            #Last PM
            echo "Start post config"
            wait_ping_hosts
            MARIADB_CS_POSTCFG_INPUT=$(build_post_config_input)
            {{- if .Values.mariadb.debug}}
            echo $PING_DEBUG
            echo $MARIADB_CS_POSTCFG_INPUT
            {{- end}}
            sh /mnt/config-map/cs_init.sh 2>&1 &
            exec /usr/sbin/runsvdir-start
        else
            #Any other PM
            echo "Start PM config"
            sh /mnt/config-map/cs_init.sh 2>&1 &
            exec /usr/sbin/runsvdir-start
        fi
    fi
fi
echo "Defaulted to sleep something is wrong"
sleep 3600