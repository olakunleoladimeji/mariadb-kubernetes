#!/bin/sh
if [ ! -z $MARIADB_CS_DEBUG ]; then
    #set +x
    echo '------------------------------'
    echo 'Starting UM Slave Post Install'
    echo '------------------------------'
    #set -x
fi
MCSDIR=/usr/local/mariadb/columnstore
mysql=( $MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf -uroot )
#TODO: configure those IP adresses
${mysql[@]} - e "grant all on *.* to root@10.5.0.1;";
${mysql[@]} - e "grant all on *.* to root@10.5.0.2;";
