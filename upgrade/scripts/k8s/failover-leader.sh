#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2023 Hewlett Packard Enterprise Development LP
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

# usage : ./failover-leader.sh <worker>
if [ $# -ne 1 ]
then
    echo "usage: ./failover-leader.sh <worker>"
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

    # An HTTP 200 response code is returned only if the pod is the master of the postgres cluster
    master="$(kubectl exec $podname -c postgres -n $namespace -- curl -sL -w "%{http_code}" -I -X GET http://localhost:8008/master -o /dev/null)"

    if [ "$master" == "200" ]
    then
        echo "$podname is master - failover to $new_master"
        kubectl exec $podname -c postgres -n $namespace -- patronictl failover --master $podname --candidate $new_master --force 2>/dev/null
        #shellcheck disable=SC2046
        while [ $(kubectl exec $new_master -c postgres -n $namespace -- curl -sL -w "%{http_code}" -I -X GET http://localhost:8008/master -o /dev/null) != 200 ] ; do echo "  waiting for master to respond"; sleep 2; done
    else
        echo "$podname is not master - do nothing"
    fi
done < <(kubectl get pods -A -l application=spilo --no-headers=true -o wide | grep $worker | awk '{print $1" " " "$2}')
