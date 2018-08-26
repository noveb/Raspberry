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

    local total_size="512M"

    log_initialisation

    test_definition $total_size

    local test_start=$(date +%s%N)
    test_runner "File IO Test"
    local test_end=$(date +%s%N)

    test_summary "File IO" "$(($(($test_end-$test_start)) / 1000000))"

    exit

}

log_initialisation () {
    mkdir -p log
    : > log/oc-val-cpu.log
    logFile=log/oc-val-cpu.log
}


test_definition () {
    test_names[0]="Preparing test files ${1}"
    test_commands[0]="sysbench --validate=on --test=fileio --file-total-size=${1} prepare"
    test_names[1]="Testing sequential write ${1}"
    test_commands[1]="sysbench --validate=on --test=fileio --file-test-mode=seqwr --file-total-size=${1} run"
    test_names[2]="Testing sequential read ${1}"
    test_commands[2]="sysbench --validate=on --test=fileio --file-test-mode=seqrd --file-total-size=${1} run"
    test_names[3]="Testing random write ${1}"
    test_commands[3]="sysbench --validate=on --test=fileio --file-test-mode=rndwr --file-total-size=${1} run"
    test_names[4]="Testing random read ${1}"
    test_commands[4]="sysbench --validate=on --test=fileio --file-test-mode=rndrd --file-total-size=${1} run"
    test_names[5]="Cleaning up test files ${1}"
    test_commands[5]="sysbench --validate=on --test=fileio --file-total-size=${1} cleanup"
}

test_runner () {
    printf "\t${SIGN_RUNNING}\t${1}\n"
    for((i=1;i<=5;i++))
    do
        printf "\t\t${SIGN_RUNNING}\t${test_names[i]}"
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
