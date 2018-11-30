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
echo "Running tests"
FAIL_STRING="@@failure@@"
mysql() {
    res=$($MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf -uroot --silent  "$1" < /dev/stdin)
    if [ $? -eq 0 ]; then
        echo $res
    else
        echo $FAIL_STRING
    fi
}

$MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf -uroot < initdb.sql #-v
tests+=( 'repeat_tst "[ $( echo SELECT 1 | mysql "$MARIADB_DATABASE" ) = 1 ]" 200' "Testing 20 times SELECT 1. Expected: 1" )
tests+=( "[ "$(echo 'SELECT COUNT(*) FROM test' | mysql "$MARIADB_DATABASE")" = 1 ]" "Testing SELECT COUNT(*) FROM test. Expected: 1" )
tests+=( "[ "$(echo 'SELECT c FROM test' | mysql "$MARIADB_DATABASE")" == "goodbye!" ]" "Testing SELECT c FROM test. Expected: goodbye!" )
tests+=( "[ "$(wc -l /var/log/mariadb/columnstore/info.log | cut -d ' ' -f 1)" -gt 0 ]" "Testing log at /var/log/mariadb/columnstore/info.log. Expected: some rows" )
{{- if .Values.mariadb.columnstore.sandbox}}
tests+=( 'repeat_tst "[ "$(echo SELECT price from transactions WHERE transaction_type = 1 ORDER BY price LIMIT 1 | mysql bookstore)" == "1.49" ]" 5' "Testing SELECT price from transactions WHERE transaction_type = 1 ORDER BY price LIMIT 1;. Expected: 1.49" )
tests+=( "[ "$(echo 'SELECT COUNT(*) FROM addresses' | mysql bookstore)" = 2666749 ]" "Testing SELECT COUNT(*) FROM addresses. Expected: 2666749" )
tests+=( "[ "$(echo 'SELECT COUNT(*) FROM books' | mysql bookstore)" = 5001 ]" "Testing SELECT COUNT(*) FROM books. Expected: 5001" )
tests+=( "[ "$(echo 'SELECT COUNT(*) FROM cards' | mysql bookstore)" = 1604661 ]" "Testing SELECT COUNT(*) FROM cards. Expected: 1604661" )
tests+=( "[ "$(echo 'SELECT COUNT(*) FROM covers' | mysql bookstore)" = 20 ]" "Testing SELECT COUNT(*) FROM covers. Expected: 20" )
tests+=( "[ "$(echo 'SELECT COUNT(*) FROM customers' | mysql bookstore)" = 2005397 ]" "Testing SELECT COUNT(*) FROM customers. Expected: 2005397" )
tests+=( "[ "$(echo 'SELECT COUNT(*) FROM emails' | mysql bookstore)" = 2566571 ]" "Testing SELECT COUNT(*) FROM emails. Expected: 2566571" )
tests+=( "[ "$(echo 'SELECT COUNT(*) FROM loyaltypoints' | mysql bookstore)" = 923008 ]" "Testing SELECT COUNT(*) FROM loyaltypoints. Expected: 923008" )
tests+=( "[ "$(echo 'SELECT COUNT(*) FROM maritalstatuses' | mysql bookstore)" = 5 ]" "Testing SELECT COUNT(*) FROM maritalstatuses. Expected: 5" )
tests+=( "[ "$(echo 'SELECT COUNT(*) FROM phones' | mysql bookstore)" = 2427033 ]" "Testing SELECT COUNT(*) FROM phones. Expected: 2427033" )
tests+=( "[ "$(echo 'SELECT COUNT(*) FROM transactions' | mysql bookstore)" = 11279171 ]" "Testing SELECT COUNT(*) FROM transactions. Expected: 11279171" )
tests+=( "[ "$(echo 'SELECT COUNT(*) FROM transactiontypes' | mysql bookstore)" = 3 ]" "Testing SELECT COUNT(*) FROM transactiontypes. Expected: 3" )
tests+=( 'repeat_tst "[ "$(echo SELECT price from transactions WHERE transaction_type = 1 ORDER BY price LIMIT 1 | mysql bookstore)" == "1.49" ]" 5' "Testing (5 iterations) SELECT price from transactions WHERE transaction_type = 1 ORDER BY price LIMIT 1;. Expected: 1.49" )
tests+=( "[ "$(echo 'SELECT sum(price) FROM transactions' | mysql bookstore)" == "115003016.41" ]" "Testing SELECT sum(price) FROM transactions. Expected: 115003016.41" )
tests+=( "[ "$(echo 'SELECT DISTINCT count(customer_id) from transactions' | mysql bookstore)" == "11279171" ]" "Testing SELECT DISTINCT count(customer_id) from transactions. Expected: 11279171" )
tests+=( "[ "$(echo 'SET @@max_length_for_sort_data = 501;SELECT p.p FROM (SELECT bookname,category, sum(cover_price) p from books group by bookname,category) p ORDER BY category LIMIT 1' | mysql bookstore)" == $FAIL_STRING ]" "Testing limited sort;. Expected: FAIL" )
tests+=( "[ "$(echo 'SET @@max_length_for_sort_data = 5001;SELECT p.p FROM (SELECT bookname,category, sum(cover_price) p from books group by bookname,category) p ORDER BY category LIMIT 1' | mysql bookstore)" == "3.49" ]" "Testing within the limit. Expected: 3.49" )
{{- end}}
start_tst tests[@] 3



# SELECT s.a,s.b FROM (
# SELECT "addresses" a, COUNT(*) b FROM addresses
# UNION ALL
# SELECT "books" a, COUNT(*) b FROM books
# UNION ALL
# SELECT "cards" a, COUNT(*) b FROM cards
# UNION ALL
# SELECT "covers" a, COUNT(*) b FROM covers
# UNION ALL
# SELECT "customers" a, COUNT(*) b FROM customers
# UNION ALL
# SELECT "emails" a, COUNT(*) b FROM emails
# UNION ALL
# SELECT "loyaltypoints" a, COUNT(*) b FROM loyaltypoints
# UNION ALL
# SELECT "maritalstatuses" a, COUNT(*) b FROM maritalstatuses
# UNION ALL
# SELECT "phones" a, COUNT(*) b FROM phones
# UNION ALL
# SELECT "transactions" a, COUNT(*) b FROM transactions
# UNION ALL
# SELECT "transactiontypes" a, COUNT(*) b FROM transactiontypes
# ) s order by s.a; 
