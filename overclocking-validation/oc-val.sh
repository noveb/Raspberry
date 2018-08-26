#!/bin/bash

SECONDS=0
tabs 4

command -v sysbench >/dev/null 2>&1 ||
{
    echo >&2 "I require sysbench but it's not installed.
    Please install it manually with 
    sudo apt-get install sysbench -y"
    exit 1
}

bash oc-val-cpu.sh

bash oc-val-ram.sh

bash oc-val-io.sh

duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
exit 0
