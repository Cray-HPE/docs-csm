#!/bin/bash
#
# MIT License
#
# (C) Copyright 2023-2024 Hewlett Packard Enterprise Development LP
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
# power_off_on_nodes.sh script is used to perform graceful/abruptive
# shutdown of the nodes under the identified rack as a part of
# Rack Resiliency procedure.
#

YELLOW='\E[1;33m'
RED='\E[1;31m'
WHITE='\E[0;37m'
GREEN='\E[1;32m'

DATE=`date "+%d-%b-%Y-%a-%H-%M-%S%p"`
HOST=`hostname`
POWER_ON_OFF_LOG="/var/log/rackresiliency/$HOST-power_on_off-$DATE.log"
mkdir -p /var/log/rackresiliency

echolog(){
        echo -e "$@"
        echo -e "$@" >>$POWER_ON_OFF_LOG
}

nodes_list()
{
    nodes=($(kubectl get nodes -l topology.kubernetes.io/zone=${rack} --no-headers | awk '{print $1}'))
    echolog "Following list of master and worker nodes are scheduled on the rack ${rack}:"
    echolog "*******************"
    for node in "${nodes[@]}"
    do
        echolog "${node}"
    done
    echolog "*******************"
}

power_off()
{
    tries=0
    MAX_RETRY=60
    SLEEP_INTERVAL=5
    username=root
    nodes_list
    echolog "${YELLOW}Are you sure you want to shutdown the above listed nodes? If yes, please enter 'y' or 'yes'${WHITE}"
    read -r -t 30 option
    if [ "${option}" = "y" ] || [ "${option}" = "yes" ]; then
        echolog "Going to shutdown above mentioned nodes of the rack ${rack}"
        for node in "${nodes[@]}"
        do
            echolog "${YELLOW}Please enter the BMC ${username} password of node ${node}:${WHITE}"
            read -r -s -t 30 password
            if [[ ${node} == "ncn-m001" ]];then
                node=${cluster}-${node}-mgmt.hpc.amslabs.hpecorp.net
            else
                node=${node}-mgmt
            fi
            system=$(curl -u ${username}:${password} -k -s https://${node}/redfish/v1/Systems/ | jq .Members | grep -i data.id | cut -d ':' -f 2 | tr -d '"' | sed -e 's/^[ \t]*//')
            node_status=$(curl -u ${username}:${password} -k -s https://${node}${system} | jq .PowerState | tr -d '"')
            if [[ ${node_status} = "Off" ]]; then
                echolog "Node ${node} is already powered off..Continuing to the next node"
                continue
            else
                echolog "${YELLOW}Do you want to perform Graceful node shutdown or Non-graceful node shutdown?"
                echolog "${YELLOW}If Graceful, please enter 'G' or 'Graceful'"
                echolog "${YELLOW}If Non-Graceful, please enter 'A' or 'Non-Graceful"
                read -r -t 30 mode
                if [ "${mode}" = "G" ] || [ "${mode}" = "Graceful" ]; then
                    echolog "Shutdowning the node ${node} Gracefully..."
                    curl https://${node}${system}Actions/ComputerSystem.Reset/ -H "Content-Type: application/json" -X POST -d '{"ResetType": "GracefulShutdown"}' -u ${username}:${password} --insecure 
                    sleep 15
                elif [ "${mode}" = "A" ] || [ "${mode}" = "Non-Graceful" ]; then
                    echolog "Shutdowning the node ${node} Non-Gracefully..."
                    curl https://${node}${system}Actions/ComputerSystem.Reset/ -H "Content-Type: application/json" -X POST -d '{"ResetType": "ForceOff"}' -u ${username}:${password} --insecure
                    sleep 15
                else
                    echolog "${RED}Invalid input or no input received from the user. Exiting${WHITE}"
                fi
            fi
            node_status=$(curl -u ${username}:${password} -k -s https://${node}${system} | jq .PowerState | tr -d '"')
            until [ ${node_status} = "Off" ]
            do
                tries=$((tries + 1))
                [ ${tries} -ge ${MAX_RETRY} ] && { echo "The node shutdown ${node} status is not properly reflected. Pls do check manually"; exit 1 ; }
                echolog "The node shutdown ${node} is still in progress, re-checking after ${SLEEP_INTERVAL} seconds"
                sleep ${SLEEP_INTERVAL}
                node_status=$(curl -u ${username}:${password} -k -s https://${node}${system} | jq .PowerState | tr -d '"')
            done
            echolog "${GREEN}Gracefully shutdowned node ${node}${WHITE}"
        done
    else
        echolog "${RED}Invalid input or no input received from the user. Exiting${WHITE}"
    fi
}

power_on()
{
    tries=0
    MAX_RETRY=60
    SLEEP_INTERVAL=5
    username=root
    nodes_list
    echolog "${YELLOW}Do you want to power on the above listed nodes? If yes, please enter 'y' or 'yes'${WHITE}"
    read -r -t 20 option
    if [ "${option}" = "y" ] || [ "${option}" = "yes" ]; then
        echolog "Going to power on the above mentioned nodes of the rack ${rack}"
        for node in "${nodes[@]}"
        do
            echolog "${YELLOW}Please enter the BMC ${username} password of node ${node}:${WHITE}"
            read -r -s -t 20 password
            if [[ ${node} == "ncn-m001" ]];then
                node=${cluster}-${node}-mgmt.hpc.amslabs.hpecorp.net
            else
                node=${node}-mgmt
            fi
            system=$(curl -u ${username}:${password} -k -s https://${node}/redfish/v1/Systems/ | jq .Members | grep -i data.id | cut -d ':' -f 2 | tr -d '"' | sed -e 's/^[ \t]*//')
            node_status=$(curl -u ${username}:${password} -k -s https://${node}${system} | jq .PowerState | tr -d '"')
            if [[ ${node_status} = "On" ]]; then
                echolog "Node ${node} is already powered on..Continuing to next node"
                continue
            else
                echolog "Powering on the node ${node}.."
                curl https://${node}${system}Actions/ComputerSystem.Reset/ -H "Content-Type: application/json" -X POST -d '{"ResetType": "On"}' -u ${username}:${password} --insecure
                sleep 15
            fi
            node_status=$(curl -u ${username}:${password} -k -s https://${node}${system} | jq .PowerState | tr -d '"')
            until [ ${node_status} = "On" ]
            do
                tries=$((tries + 1))
                [ ${tries} -ge ${MAX_RETRY} ] && { echo "The node-${node} power on status is not properly reflected. Pls do check manually"; exit 1 ; }
                echolog "The node-${node} power on is still in progress, re-checking after ${SLEEP_INTERVAL} seconds"
                sleep ${SLEEP_INTERVAL}
                node_status=$(curl -u ${username}:${password} -k -s https://${node}${system} | jq .PowerState | tr -d '"')
            done
            echolog "${GREEN}Powered on the ${node} successfully.${WHITE}"
        done
    else
        echolog "${RED}Invalid input or no input received from the user. Exiting${WHITE}"
    fi
}

while getopts c:r:s:h option
    do
        case "${option}" in
            c) cluster=${OPTARG}
               ;;
            r) rack=${OPTARG}
               ;;
            s) action=${OPTARG}
               ${action}
               ;;
            h | \?) echo "Usage:"
               echolog " power_off_on.sh -c <cluster_name> -r <rack_label_name> -s <power_off> # To power off the rack nodes"
               echolog " power_off_on.sh -c <cluster_name> -r <rack_label_name> -s <power_on> # To power on the rack nodes"
               exit 1;;
        esac
    done

# no options mentioned. bail out
if [[  -z ${action} ]]; then
    echolog "No options passed to the script. Please provide one of the options of power_off or power_on along with the rack name as below"
    echolog " power_off_on.sh -c <cluster_name> -r <rack_label_name> -s <power_off> # To power off the rack nodes"
    echolog " power_off_on.sh -c <cluster_name> -r <rack_label_name> -s <power_on> # To power on the rack nodes"
    exit 1
fi
