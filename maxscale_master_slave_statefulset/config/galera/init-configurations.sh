#!/bin/sh
# the path to the target directory needs to be passed as first argument

set -ex

APPLICATION=$(hostname -f | cut -d '.' -f 2 | cut -d '-' -f 1)
ENVIRONMENT=$(hostname -f | cut -d '.' -f 2 | cut -d '-' -f 2)
ADMIN_USER=$(cat /mnt/secrets/admin-username)
ADMIN_PWD=$(cat /mnt/secrets/admin-password)
REPL_USER=$(cat /mnt/secrets/repl-username)
REPL_PWD=$(cat /mnt/secrets/repl-password)

for filename in /mnt/config-template/*; do
    sed -e "s/<<MASTER_HOST>>/$MASTER_HOST/g" \
        -e "s/{{ .Values.ADMIN_USERNAME }}/$ADMIN_USER/g" \
        -e "s/{{ .Values.ADMIN_PASSWORD }}/$ADMIN_PWD/g" \
        -e "s/{{ .Values.REPLICATION_USERNAME }}/$REPL_USER/g" \
        -e "s/{{ .Values.REPLICATION_PASSWORD }}/$REPL_PWD/g" \
        $filename > $1/$(basename $filename)
done

# if [ "$2" != "" ]; then
#    until mysql -h $APPLICATION-$ENVIRONMENT-galera-$2.$APPLICATION-$ENVIRONMENT-mariadb-galera -u $REPL_USER -p$REPL_PWD -e "SELECT 1"
#    do
#        sleep 5
#    done
# fi
