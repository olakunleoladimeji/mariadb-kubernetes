#!/bin/bash
export PASS_MSG="\033[0;32m✔ Pass \033[0m"
export FAIL_MSG="\033[0;31m✘ Fail \033[0m"
start_tst()
{
    declare -a tsts=("${!1}")
    spacer=''
    echo ""
    if [ ! -z "$2" ]; then
        for ((i=0;i<=$2;i++));do spacer="$spacer "; done;
    fi
    for (( i=0; i<${#tsts[@]}; i=$i+2 ));
    do
        #echo ">>>>"${tsts[$i]}"<<<<"
        test=${tsts[$i]}
        test_name=${tsts[$i+1]}
        echo -ne "$spacer"[$(($i/2+1))/$((${#tsts[@]}/2))] ${test_name} ""
        
        if eval "$test"; then
            echo -ne "$PASS_MSG\r\n"
        else
            echo -ne "$FAIL_MSG\r\n"
        fi
    done
}

export start_test


repeat_tst() {
    test="$1"
    # echo ""
    # echo ">$1<"
    # echo ">>$2<<"
    if [ ! -z "$2" ]; then
        iterations="$2"
        strlen=${#iterations}
        for (( k=1; k<$((iterations+1)); k++ ));
        do            
            for (( j=0; j<$((strlen-${#k})); j++ )); do echo -en '0' ; done;
            echo -en "$k"
            for (( j=0; j<$((strlen)); j++ )); do echo -en '\b' ; done;
            if ! eval "$test"; then
                return 1
            fi
        done;

    fi
}

export repeat_tst

export MCSDIR=/usr/local/mariadb/columnstore

# export MARIADB_ROOT_PASSWORD='this is an example test password'
# export MARIADB_USER='0123456789012345'
# export MARIADB_PASSWORD='my cool mariadb password'
export MARIADB_DATABASE='my cool mariadb database'
sed -i s/\#\#test_db_name\#\#/"$MARIADB_DATABASE"/g ./initdb.sql

mysql() {
    $MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf -uroot --silent  "$MARIADB_DATABASE" < /dev/stdin
}

$MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf -uroot < initdb.sql #-v
tests+=( 'repeat_tst "[ $( echo SELECT 1 | mysql ) = 1 ]" 20' "Testing 20 times SELECT 1. Expected: 1" )
tests+=( "[ "$(echo 'SELECT COUNT(*) FROM test' | mysql)" = 1 ]" "Testing SELECT COUNT(*) FROM test. Expected: 1" )
tests+=( "[ "$(echo 'SELECT c FROM test' | mysql)" == "goodbye!" ]" "Testing SELECT c FROM test. Expected: goodbye!" )
tests+=( "[ "$(wc -l /var/log/mariadb/columnstore/info.log | cut -d ' ' -f 1)" -gt 0 ]" "Testing log at /var/log/mariadb/columnstore/info.log. Expected: some rows" )
start_tst tests[@] 3

