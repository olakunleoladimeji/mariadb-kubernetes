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