#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

# usage : ./failover-leader.sh  <worker>
if [  $# -ne 1 ]
then
    echo "usage: ./failover-leader.sh  <worker>"
    exit 1
fi

worker=$1

# For each postgres pod running on the specified worker, if it is the master (aka leader or primary), failover to a different cluster member
while read namespace podname
do
    echo "NAME : $podname"
    podnum=${podname: -1}
    podbasename=`echo $podname | awk -F'-' 'sub(FS $NF,x)'`

    if [ "$podnum" == "1" ] || [ "$podnum" == "2" ]
    then
        new_master="$podbasename-0"
    else
        new_master="$podbasename-1"
    fi

    # An http 200 response code is returned only if the pod is the master  of the postgres cluster
    master="$(kubectl exec $podname -c postgres -n $namespace -- curl -sL -w "%{http_code}" -I -X GET http://localhost:8008/master -o /dev/null)"

    if [ "$master" == "200" ]
    then
        echo "$podname is master - failover to $new_master"
        kubectl exec $podname -c postgres -n $namespace -- patronictl failover --master $podname --candidate $new_master --force 2>/dev/null
        while [ $(kubectl exec $new_master -c postgres -n $namespace -- curl -sL -w "%{http_code}" -I -X GET http://localhost:8008/master -o /dev/null) != 200 ] ; do echo "  waiting for master to respond"; sleep 2; done
    else
        echo "$podname is not master - do nothing"
    fi
done < <(kubectl get pods -A -l application=spilo --no-headers=true -o wide | grep $worker | awk '{print $1" " " "$2}')
