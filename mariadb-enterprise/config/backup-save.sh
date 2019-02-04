#!/bin/bash

BACKUP_DIR=backup-$HOSTNAME-$(date +%Y-%m-%d-%H-%M-%S)

echo "The backup will be in $BACKUP_DIR"

BACKUP_DIR=/backup-storage/$BACKUP_DIR

mkdir -p $BACKUP_DIR

if [[ "$CLUSTER_TOPOLOGY" == "standalone" ]] || [[ "$CLUSTER_TOPOLOGY" == "masterslave" ]]; then
    mariabackup --backup --target-dir=$BACKUP_DIR --user=root
elif [[ "$CLUSTER_TOPOLOGY" == "galera" ]]; then
    mariabackup --backup --galera-info --target-dir=$BACKUP_DIR --user=root
fi

mariabackup --prepare --target-dir=$BACKUP_DIR --user=root