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


#drain all the master/ worker ncn nodes under identified rack

if [ -z "$1" ]; then
  echo "Error: missing rack name."
  echo "Usage: ./drain_nodes.sh <rack id>" 
  echo "Ex:    ./drain_nodes.sh rack-1"
  exit 1
fi

RACKID=${1}

# get ncn nodes under zone/ rack
ncn_nodes_list=($(kubectl get nodes -l topology.kubernetes.io/zone=${RACKID} --no-headers | awk '{print $1}'))

for ncn_node in "${ncn_nodes_list[@]}"
do
    echo "draining the ncn node ${ncn_node}..."
    kubectl drain $ncn_node --ignore-daemonsets --force --delete-local-data
done
