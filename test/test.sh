#!/bin/bash
. ./helpers/testfwk.sh

tests+=( "./mariadb-initdb/run.sh" "Test mariadb-initdb" )

if [ ${#tests[@]} -gt 0 ]; then
    echo ""
    echo "Running test suite for Columnstore"
    echo "----------------------------------------------------------------" 
    start_tst tests[@]
fi