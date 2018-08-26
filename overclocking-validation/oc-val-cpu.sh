#!/bin/bash

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

    local test_runs=5
    local max_prime=14713
    local num_threads=4

    log_initialisation

    test_definition $test_runs $num_threads $max_prime

    local test_start=$(date +%s%N)
    test_runner "CPU Test" $test_runs
    local test_end=$(date +%s%N)

    test_summary "CPU" "$(($(($test_end-$test_start)) / 100000))"

    echo "${isWarning}" "${isFailure}"

    exit

}

log_initialisation () {
    mkdir -p log
    : > log/oc-val-cpu.log
    logFile=log/oc-val-cpu.log
}

test_definition () {
    for((j=1;j<=$1;j++))
    do
        test_names[j]="Testing CPU run ${j}"
        test_commands[j]="sysbench --validate=on --test=cpu --num-threads=${2} --cpu-max-prime=${3} run"
    done
}

test_runner () {
    printf "  ${SIGN_RUNNING}  ${1}\n"
    for((i=1;i<=$2;i++))
    do
        printf "\t${SIGN_RUNNING}\t${test_names[i]}"
        echo "${test_names[i]}" >> ${logFile}
        local test_start=$(date +%s%N)
        (${test_commands[i]}) &>>${logFile}
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
    printf "\r\t${SIGN}\t${2}, runtime $((${3} / 60000))m $(($((${3} / 1000)) % 60))s $((${3} % 1000))ms\n"
}

test_summary () {
    local runtime="$((${2} / 60000))m $(($((${2} / 1000)) % 60))s $((${2} % 1000))ms"
    if [[ "${isFailure}" == "true" ]];
    then printf "  ${SIGN_FAILURE}  ${1} is not OK! There are fatal errors! Runtime ${runtime}\n"
    elif [[ "${isWarning}" == "true" ]];
    then printf "  ${SIGN_WARNING}  ${1} is maybe not OK! There are warnings! Runtime ${runtime}\n"
    else printf "  ${SIGN_SUCCESS}  ${1} is OK! Runtime ${runtime}\n"
    fi
}

main "$@"

echo "Uh, this should not happen!"
exit 1
