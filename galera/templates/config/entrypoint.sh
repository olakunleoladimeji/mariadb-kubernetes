#!/bin/bash
set -ex

/etc/init.d/ssh start

[[ $(hostname) =~ -([0-9]+)$ ]] || exit 1
server_id=${BASH_REMATCH[1]}

if [[ $server_id -eq 0 ]]; then
    if [[ ! -d /var/lib/mysql/mysql ]]; then
        # fix file permissions for fluentd
        touch /var/log/mysql/slow-query.log
        chmod 666 /var/log/mysql/slow-query.log
        touch /var/log/mysql/error.log
        chmod 666 /var/log/mysql/error.log

        # init database
        mysql_install_db --user=mysql --datadir=/var/lib/mysql

        # start mysql and create new cluster
        service mysql start --wsrep-new-cluster

        # fix debian account password
        DEBIAN_PASS=$(grep -i "password" /etc/mysql/debian.cnf | head -1 | awk 'match($0, "^password = (.*)$", m) {print m[1]}')
        mysql -vvv -Bse "GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '${DEBIAN_PASS}';FLUSH PRIVILEGES;"

        # create replication (maxscale) and admin users
        mysql -vvv -Bse "CREATE USER '{{REPLICATION_USERNAME}}'@'127.0.0.1' IDENTIFIED BY '{{REPLICATION_PASSWORD}}';"
        mysql -vvv -Bse "CREATE USER '{{REPLICATION_USERNAME}}'@'%' IDENTIFIED BY '{{REPLICATION_PASSWORD}}';"
        mysql -vvv -Bse "GRANT ALL ON *.* TO '{{REPLICATION_USERNAME}}'@'127.0.0.1' WITH GRANT OPTION;"
        mysql -vvv -Bse "GRANT ALL ON *.* TO '{{REPLICATION_USERNAME}}'@'%' WITH GRANT OPTION;"

        mysql -vvv -Bse "CREATE USER '{{ADMIN_USERNAME}}'@'127.0.0.1' IDENTIFIED BY '{{ADMIN_PASSWORD}}';"
        mysql -vvv -Bse "CREATE USER '{{ADMIN_USERNAME}}'@'%' IDENTIFIED BY '{{ADMIN_PASSWORD}}';"
        mysql -vvv -Bse "GRANT ALL ON *.* TO '{{ADMIN_USERNAME}}'@'127.0.0.1' WITH GRANT OPTION;"
        mysql -vvv -Bse "GRANT ALL ON *.* TO '{{ADMIN_USERNAME}}'@'%' WITH GRANT OPTION;"

        mysql -vvv -Bse "FLUSH PRIVILEGES;"
    else
        # check if any other instance is up
        PING0=$(mysql --host={{APPLICATION}}-{{ENVIRONMENT}}-galera-0.{{APPLICATION}}-{{ENVIRONMENT}}-mariadb-galera -Bse "SELECT 1" -u{{ADMIN_USERNAME}} -p{{ADMIN_PASSWORD}}) || PING0=0
        PING1=$(mysql --host={{APPLICATION}}-{{ENVIRONMENT}}-galera-1.{{APPLICATION}}-{{ENVIRONMENT}}-mariadb-galera -Bse "SELECT 1" -u{{ADMIN_USERNAME}} -p{{ADMIN_PASSWORD}}) || PING1=0
        PING2=$(mysql --host={{APPLICATION}}-{{ENVIRONMENT}}-galera-2.{{APPLICATION}}-{{ENVIRONMENT}}-mariadb-galera -Bse "SELECT 1" -u{{ADMIN_USERNAME}} -p{{ADMIN_PASSWORD}}) || PING2=0

        if [[ $PING0 -eq 1 ]] || [[ $PING1 -eq 1 ]] || [[ $PING2 -eq 1 ]]; then
            # start mysql
            service mysql start
        else
            # start mysql and create new cluster
            rm /var/lib/mysql/galera.cache
            rm /var/lib/mysql/grastate.dat
            rm /var/lib/mysql/gvwstate.dat
            service mysql start --wsrep-new-cluster
        fi
    fi
else
    if [[ ! -d /var/lib/mysql/mysql ]]; then
        # fix file permissions for fluentd
        touch /var/log/mysql/slow-query.log
        chmod 666 /var/log/mysql/slow-query.log
        touch /var/log/mysql/error.log
        chmod 666 /var/log/mysql/error.log

        # init database
        mysql_install_db --user=mysql --datadir=/var/lib/mysql
    fi

    # start mysql
    service mysql start
fi

# don't exit the process
tail -f /dev/null