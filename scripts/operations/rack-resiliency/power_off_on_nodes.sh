#!/bin/bash
#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

# power_off_on.sh script is used to perform graceful shutdown
# of the nodes under the identified rack as a part of
# Rack Resiliency procedure.

YELLOW='\E[1;33m'
RED='\E[1;31m'
WHITE='\E[0;37m'
GREEN='\E[1;32m'

#rack=$1
nodes=($(kubectl get nodes -l topology.kubernetes.io/zone=${rack} --no-headers | awk '{print $1}'))

nodes_list()
{
    echo "Following list of master and worker nodes are scheduled on the rack ${rack}:"
    for node in "${nodes[@]}"
    do
        echo "${node}"
    done
}

power_off()
{
    tries=0
    #MAX_RETRY=30
    MAX_RETRY=2
    SLEEP_INTERVAL=5
    nodes_list
    echo "Are you sure you want to shutdown the above listed nodes"
    echo "If you want to proceed with the listed nodes shutdown, please enter 'y' or 'yes'"
    read -r -t 20 option
    echo ${option}
    if [ "${option}" = "y" ] || [ "${option}" = "yes" ]; then
        echo "Going to shutdown above mentioned nodes of the rack ${rack}"
        for node in "${nodes[@]}"
        do
            echo "Shutdowning the node ${node}..."
            ipmitool -I lanplus -U ${username} -P ${password} -H ${node} power soft
            sleep 30
            node_status=$(ipmitool -I lanplus -U ${username} -P ${password} -H ${node} power status | awk '{print $4}')
            until [ ${node_status} = "off" ]
            do
                tries=$((tries + 1))
                [ ${tries} -ge ${MAX_RETRY} ] && { echo "The node shutdown ${node} status is not properly reflected. Pls do check manually"; exit 1 ; }
                echo "The node shutdown ${node} is still in progress, re-checking after ${SLEEP_INTERVAL} seconds"
                sleep ${SLEEP_INTERVAL}
                node_status=$(ipmitool -I lanplus -U ${username} -P ${password} -H ${node} power status | awk '{print $4}')
            done
            echo "Gracefully shutdowned node ${node}"
        done
    else
        echo "Invalid input or no input received from the user. Exiting"
    fi
}

power_on()
{
    nodes_list
    echo "Do you want to power on the above listed nodes?"
    echo "If you want to proceed with the listed nodes power on. please enter 'y' or 'yes'"
    read -r -t 20 option
    echo ${option}
    if [ "${option}" = "y" ] || [ "${option}" = "yes" ]; then
        echo "Going to power on the above mentioned nodes of the rack ${rack}"
        for node in "${nodes[@]}"
        do
            echo "Powering on the node ${node}.."
            ipmitool -I lanplus -U ${username} -P ${password} -H ${node} power on
            sleep 30
            node_status=$(ipmitool -I lanplus -U ${username} -P ${password} -H ${node} power status | awk '{print $4}')
            until [ ${node_status} = "on" ]
            do
                tries=$((tries + 1))
                [ ${tries} -ge ${MAX_RETRY} ] && { echo "The node-${node} power on status is not properly reflected. Pls do check manually"; exit 1 ; }
                echo "The node-${node} power on is still in progress, re-checking after ${SLEEP_INTERVAL} seconds"
                sleep ${SLEEP_INTERVAL}
                node_status=$(ipmitool -I lanplus -U ${username} -P ${password} -H ${node} power status | awk '{print $4}')
            done
            echo "Powered on the ${node} successfully."
        done
    else
        echo "Invalid input or no input received from the user. Exiting"
    fi
}

while getopts r:s:h option
    do
        case "${option}" in
            r) rack=${OPTARG}
               ;;
            s) action=${OPTARG}
               ${action}
               ;;
            h | \?) echo "Usage:"
               echo " power_off_on.sh -r <rack_label_name> -s <power_off> # To power off the rack nodes"
               echo " power_off_on.sh -r <rack_label_name> -s <power_on> # To power on the rack nodes"
               exit 1;;
        esac
    done
