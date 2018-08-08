#!/bin/sh
# 2018 (C) MariaDB Corporation
# This script customizes templates based on the parameters passed to a command-line tool
# the path to the target directory needs to be passed as first argument

function expand_templates() {
    sed -e "s/{{MASTER_HOST}}/$MASTER_HOST/g" \
        -e "s/{{APPLICATION}}/$APPLICATION/g" \
        -e "s/{{ENVIRONMENT}}/$ENVIRONMENT/g" \
        -e "s/{{ADMIN_USER}}/$ADMIN_USER/g" \
        -e "s/{{ADMIN_PASSWORD}}/$ADMIN_PWD/g" \
        -e "s/{{REPLICATION_USER}}/$REPL_USER/g" \
        -e "s/{{REPLICATION_PASSWORD}}/$REPL_PWD/g" \
        $1
}

set -ex
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

APPLICATION=$(hostname -f | cut -d '.' -f 2 | cut -d '-' -f 1)
ENVIRONMENT=$(hostname -f | cut -d '.' -f 2 | cut -d '-' -f 2)
ADMIN_USER=$(cat /mnt/secrets/admin-username)
ADMIN_PWD=$(cat /mnt/secrets/admin-password)
REPL_USER=$(cat /mnt/secrets/repl-username)
REPL_PWD=$(cat /mnt/secrets/repl-password)
DB_HOST="$(hostname -f | cut -d '.' -f 1).$(hostname -f | cut -d '.' -f 2)"

if [ "$1" == "maxscale" ]; then
    # ensure we replace with a configurations that will fail
    MASTER_HOST="should-not-be-used-here"
    expand_templates /mnt/config-template/maxscale.cnf >> /etc/maxscale-cfg/maxscale.cnf
else
    # if this is not a maxscale instance, make sure to ask maxscale who is the master
    MASTER_HOST=$(perl "$DIR"/register-instance-pkg.pl $DB_HOST http $APPLICATION-$ENVIRONMENT-mdb-mxs-0.$APPLICATION-$ENVIRONMENT-mdb-clust 8989 admin mariadb)
    if [[ ! -d /var/lib/mysql/mysql ]]; then
       if [[ "$MASTER_HOST" == "NO MASTER" ]]; then
          # this is the master and it's the first run, ensure maxscale user is initialized
	  expand_templates /mnt/config-template/users.sql > /docker-entrypoint-initdb.d/init.sql
       else
	  # 
          # a first run on a slave
          # mysqldump -h $MASTER_HOST -u $REPL_USER -p$REPL_PWD --all-databases -A -Y --add-drop-database --add-drop-table --add-drop-trigger --allow-keywords --compact --master-data --lock-all-tables -F --flush-privileges --gtid -Q > /docker-entrypoint-initdb.d/slave.sql
          expand_templates /mnt/config-template/replication.sql >> /docker-entrypoint-initdb.d/init.sql
       fi
   fi
   cp /mnt/config-template/register-instance-pkg.pl /mnt/config-map/register-instance-pkg.pl
   cp /mnt/config-template/start-mariadb-instance.sh /mnt/config-map/start-mariadb-instance.sh
fi

#for filename in /mnt/config-template/*; do
#    sed -e "s/{{MASTER_HOST}}/$MASTER_HOST/g" \
#        -e "s/{{APPLICATION}}/$APPLICATION/g" \
#	-e "s/{{ENVIRONMENT}}/$ENVIRONMENT/g" \
#        -e "s/{{ADMIN_USER}}/$ADMIN_USER/g" \
#        -e "s/{{ADMIN_PASSWORD}}/$ADMIN_PWD/g" \
#        -e "s/{{REPLICATION_USER}}/$REPL_USER/g" \
#        -e "s/{{REPLICATION_PASSWORD}}/$REPL_PWD/g" \
#        $filename > $1/$(basename $filename)
#done
