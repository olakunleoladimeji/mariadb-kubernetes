#!/bin/bash
set -e
MCSDIR=/usr/local/mariadb/columnstore
MCSBINDIR=$MCSDIR/mysql/bin
# file used to track / record initialization and prevent subsequent rerun
FLAG="$MCSDIR/etc/container-initialized"
# /usr/local/mariadb/columnstore/mysql/bin/mysql -h 127.0.0.1 "select 1"
if [ -e $FLAG ] && [ -e ${MSCBINDIR}/mcsadmin]; then
    #Container already initialized
    # check system status
    ${MSCBINDIR}/mcsadmin getSystemStatus | tail -n +9 | grep System | grep -v "System and Module statuses" | grep -q 'System.*ACTIVE'
    ${MSCBINDIR}/mysql -h 127.0.0.1 "select 1"
    exit 0
fi


