#!/bin/bash
. ./helpers/testfwk.sh
export MCSDIR=/usr/local/mariadb/columnstore

# export MARIADB_ROOT_PASSWORD='this is an example test password'
# export MARIADB_USER='0123456789012345'
# export MARIADB_PASSWORD='my cool mariadb password'
export MARIADB_DATABASE='my cool mariadb database'

cp ./mariadb-initdb/initdb.sql /docker-entrypoint-initdb.d/initdb.sql
sed -i s/\#\#test_db_name\#\#/"$MARIADB_DATABASE"/g /docker-entrypoint-initdb.d/initdb.sql

mysql() {
    $MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf -uroot --silent  "$MARIADB_DATABASE" < /dev/stdin
}

$MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf -uroot  < /docker-entrypoint-initdb.d/initdb.sql #-v

tests+=( 'repeat_tst "[ $( echo SELECT 1 | mysql ) = 1 ]" 20' "Testing 20 times SELECT 1. Expected: 1" )
tests+=( "[ "$(echo 'SELECT COUNT(*) FROM test' | mysql)" = 1 ]" "Testing SELECT COUNT(*) FROM test. Expected: 1" )
tests+=( "[ "$(echo 'SELECT c FROM test' | mysql)" == "goodbye!" ]" "Testing SELECT c FROM test. Expected: goodbye!" )
tests+=( "[ "$(wc -l /var/log/mariadb/columnstore/info.log | cut -d ' ' -f 1)" -gt 0 ]" "Testing log at /var/log/mariadb/columnstore/info.log. Expected: some rows" )
start_tst tests[@] 3
