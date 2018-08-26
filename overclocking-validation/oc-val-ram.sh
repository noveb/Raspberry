#!/bin/bash
tabs 4

# Some special charakters constants
SIGN_RUNNING='\e[33m\u2753\e[0m'
SIGN_WARNING='\e[33m\u2757\e[0m'
SIGN_FAILURE='\e[31m\u2716\e[0m'
SIGN_SUCCESS='\e[32m\u2714\e[0m'

# Check if sysbench is installed
command -v sysbench >/dev/null 2>&1 ||
{
    printf >&2 "I require sysbench but it's not installed.
    Please install it manually with
    sudo apt-get install sysbench -y"
    exit 1
}

main () {

    printf "\n"

    local test_runs=10

    log_initialisation

    test_definition

    local test_start=$(date +%s%N)
    test_runner "RAM Test" $test_runs
    local test_end=$(date +%s%N)

    test_summary "RAM" "$(($(($test_end-$test_start)) / 1000000))"

    exit

}


log_initialisation () {
    mkdir -p log
    : > log/oc-val-cpu.log
    logFile=log/oc-val-cpu.log
}

test_definition () {
    test_names[1]="Testing RAM random write"
    test_commands[1]="sysbench --validate=on --test=memory --num-threads=4 --memory-block-size=1K --memory-total-size=3G --memory-access-mode=rnd --memory-oper=write run"
    test_names[2]="Testing RAM random read"
    test_commands[2]="sysbench --validate=on --test=memory --num-threads=4 --memory-block-size=1K --memory-total-size=3G --memory-access-mode=rnd --memory-oper=read run"
    test_names[3]="Testing RAM sequential write"
    test_commands[3]="sysbench --validate=on --test=memory --num-threads=4 --memory-block-size=512M --memory-total-size=3G --memory-access-mode=seq --memory-oper=write run"
    test_names[4]="Testing RAM sequential read"
    test_commands[4]="sysbench --validate=on --test=memory --num-threads=4 --memory-block-size=512M --memory-total-size=3G --memory-access-mode=seq --memory-oper=read run"
}

test_runner () {
    printf "\t${SIGN_RUNNING}\t${1}\n"
    for((i=1;i<=4;i++))
    do
        printf "\t\t${SIGN_RUNNING}\t${test_names[i]}"
        echo "${test_names[i]}" >> ${logFile}
        local test_start=$(date +%s%N)
        for((j=1;j<=$2;j++))
        do
            (${test_commands[i]}) &>>${logFile}
        done
        local test_end=$(date +%s%N)
        local result=$(sed -n "/${test_names[i]}/,//p" ${logFile})
        test_evaluation "${result}" "${test_names[i]}" "$(($(($test_end-$test_start)) / 1000000))"
    done
}

test_evaluation () {
    if [[ "${1}" == *"FATAL"* ]];
    then local SIGN=$SIGN_FAILURE; isFailure=true;
    elif [[ "${1}" == *"WARNING"* ]];
    then local SIGN=$SIGN_WARNING; isWarning=true;
    else local SIGN=$SIGN_SUCCESS
    fi
    printf "\r\t\t${SIGN}\t${2}, runtime $((${3} / 60000))m $(($((${3} / 1000)) % 60))s $((${3} % 1000))ms\n"
}

test_summary () {
    local runtime="$((${2} / 60000))m $(($((${2} / 1000)) % 60))s $((${2} % 1000))ms"
    if [[ "${isFailure}" == "true" ]];
    then printf "\t${SIGN_FAILURE}\t${1} is not OK! There are fatal errors! Runtime ${runtime}\n"
    elif [[ "${isWarning}" == "true" ]];
    then printf "\t${SIGN_WARNING}\t${1} is maybe not OK! There are warnings! Runtime ${runtime}\n"
    else printf "\t${SIGN_SUCCESS}\t${1} is OK! Runtime ${runtime}\n"
    fi
}

main "$@"

echo "Uh, this should not happen!"
exit 1
