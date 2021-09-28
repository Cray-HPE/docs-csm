#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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
# Given a postgres cluster name and namespace, reinitialize any members with lag.
#   Fail if no leader is found.
#   Succeed if no lag is present.
#   Reinitialize any cluster members found to have lag >0 or unknown.
#   Do not wait for the reinitialization to complete.
#   Save any output to /tmp/reinit-postgres.txt
#
# Patronctl json output:
#   Leader : .Role == "Leader"
#     Lag : .Lag in MB is always ""
#   Member : .Role == ""
#     Lag : .Lag in MB can be >=0 or "unknown"

# Check usage
if [ $# -ne 2 ]
then
    echo "Usage:   $0 <cluster> <namespace>"
    echo "example: $0 cray-smd-postgres services"
    exit 1
fi

# Set postgres cluster name and namespace
c_name=$1
c_ns=$2

date >> /tmp/reinit-postgres.txt 2>&1

# Get the postgres leader
c_leader=$(kubectl exec "${c_name}-0" -c postgres -n ${c_ns} -- patronictl list -f json 2>/dev/null | jq -r '.[] | select((.Role == "Leader") and (.State =="running")) | .Member')

if [[ -z $c_leader ]]; then
    echo "No Leader exists for $c_name cluster - unable to reinit." >> /tmp/reinit-postgres.txt 2>&1
    exit 1
fi

# Get the cluster details from the leader
c_cluster_details=$(kubectl exec ${c_leader} -c postgres -it -n ${c_ns} -- patronictl list -f json)

# Determine the max lag across all members, unknown lag count across all members, list of lagging member by pod name
c_max_lag=$(echo $c_cluster_details | jq '[.[] | select((.Role == "") and (."Lag in MB" != "unknown"))."Lag in MB"] | max')
c_unknown_lag=$(echo $c_cluster_details | jq '.[] | select(.Role == "")."Lag in MB"' | grep "unknown" | wc -l)
c_members_lagging=$(echo $c_cluster_details | jq -r '.[] | select((.Role == "") and ((."Lag in MB" > 0) or (."Lag in MB" == "unknown"))).Member')

# Exit with success if no lag is found
if [[ $c_unknown_lag -eq 0 ]] && [[ $c_max_lag -eq 0 ]]; then
    echo "No lag was found for $c_name cluster - reinit not needed." >> /tmp/reinit-postgres.txt 2>&1
    exit 0
fi

# Reinit any members found to be lagging ( >0 or "unknown" )
for member in $c_members_lagging
do
    kubectl exec $c_leader -n $c_ns -c postgres -- patronictl reinit $c_name $member --force >> /tmp/reinit-postgres.txt 2>&1
done

