#!/bin/bash

MARIADB_HOST="sa-test-mariadb"
MARIADB_USER="admin"
MARIADB_PASSWORD="5LVTpbGE2cGFtw69"
MARIADB_PORT="3306"
MARIADB_CLIENT="mysql -h ${MARIADB_HOST} -P ${MARIADB_PORT} -u ${MARIADB_USER} -p${MARIADB_PASSWORD}"

set -ex

# temporary data store
mkdir -p /tmp/bookstore
cd /tmp/bookstore

# download online data
curl https://downloads.mariadb.com/sample-data/books5001.tar | tar -x

# expand csv files
gzip -d *.gz

# create test database
echo "DROP DATABASE IF EXISTS test; CREATE DATABASE test;" | ${MARIADB_CLIENT}

# create test tables
sed -e "s/%DB%/test/g" 01_load_tx_init.sql | ${MARIADB_CLIENT}

# load data from CSV
sed -e "s/%DB%/test/g" -e "s/%CSV%/$(pwd | sed -e 's/\//\\\//g')\\//g" 02_load_tx_ldi.sql | ${MARIADB_CLIENT}

# finally, run the test cases
cd /usr/share/mysql/mysql-test
./mtr --extern host="${MARIADB_HOST}" --extern user="${MARIADB_USER}" --extern password="${MARIADB_PASSWORD}" --force --verbose --suite=bookstore --max-test-fail=0 --skip-test=short_sort_length
