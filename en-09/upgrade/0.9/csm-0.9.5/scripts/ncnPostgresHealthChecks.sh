#!/bin/bash

# Copyright 2020-2021 Hewlett Packard Enterprise Development LP
#
# For each postgres cluster, the ncnPostgresHealthChecks script determines
# the leader pod and reports the status of all postgres pods in the cluster.
#
# Returned results are not verified.
#
# The ncnPostgresHealthChecks script can be run on any worker or master ncn
# node from any directory. The ncnPostgresHealthChecks script can be run
# before and after an NCN node is rebooted.
#

echo "             +++++ NCN Postgres Health Checks +++++";
echo "=== Can Be Executed on any ncn worker or master node. ==="
hostName=$(hostname)
echo "=== Executing on $hostName, $(date) ==="

echo
echo "=== Postgresql Operator Version ==="
kubectl get pod -n services -l "app.kubernetes.io/name=postgres-operator" \
        -o jsonpath='{..image}' | xargs -n 1 | grep postgres | uniq

echo
echo "=== List of Postgresql Clusters Using Operator ==="
kubectl get postgresql -A
postgresClusters="$(kubectl get postgresql -A | awk '/postgres/ || NR==1' | \
                    grep -v NAME | awk '{print $1","$2}')"

echo
echo "=== Look at patronictl list info for each cluster, determine and attach \
to leader of each cluster ==="
echo "=== Report status of postgres pods in cluster ==="

dottedLine="------------------------------------------------------------------\
--------------------------------"
echo       "---${dottedLine}"
echo

for c in $postgresClusters
do
        # NameSpace and postgres cluster name
        c_ns="$(echo $c | awk -F, '{print $1;}')"
        c_name="$(echo $c | awk -F, '{print $2;}')"
        # Get postgres pods for this cluster name:
        members="$(kubectl get pod -n $c_ns -l "cluster-name=$c_name,application=spilo" \
                           -o custom-columns=NAME:.metadata.name --no-headers)"
        numMembers=$(echo "$members" | wc -l)
        
        # Determine patroni version - remove carriage return without line feed.
        # Set a delay of 10 seconds for use with timeout command:
        Delay=10
        for member_i in $members
        do
            patronictlVersion=$(timeout -k 4 --preserve-status --foreground $Delay \
kubectl exec -it -n $c_ns -c postgres $member_i -- patronictl version | \
awk '{ sub("\r", "", $3); print $3 }'; )
            
            # Check response in case command hung or timed out.
            # If no response, check the next cluster member:
            if [[ -n $patronictlVersion ]]
            then
                break
            else
                continue
            fi
        done
        
	patronictlCmd=""
	case $patronictlVersion in
            "1.6.4" )
                patronictlCmd="\$(timeout -k 4 --preserve-status --foreground \
$Delay kubectl -n $c_ns exec \$m -- patronictl list 2>/dev/null | awk ' \$8 == \
 \"Leader\" && \$10 == \"running\" {print \$4}')"
                ;;
            "1.6.5" )
                patronictlCmd="\$(timeout -k 4 --preserve-status --foreground \
$Delay kubectl -n $c_ns exec \$m -- patronictl list 2>/dev/null | awk ' \$6 == \
\"Leader\" && \$8 == \"running\" {print \$2}')"
                ;;
            * )
                echo "Unexpected Patronictl version \"$patronictlVersion\" for \
the $c_name postgres clusters in the $c_ns namespace."
                echo
                echo $dottedLine
                echo $dottedLine
                echo
                continue
                ;;
        esac
        
	# Find the leader:
        podDescribe=" non-leader"
        for m in $members
        do
            eval leader="$patronictlCmd"
            if [ -n "$leader" ]
            then
                break;
            fi
        done
        if [ -z "$leader" ]
        then
            podDescribe=""
            echo "=== ********************************************************\
************************** ==="
            echo "=== ****** Unable to determine a leader for the $c_name cluster in \
$numMembers pods ****** ==="
            echo "=== ********************************************************\
************************** ==="
            echo
            echo "--- Patronictl version: $patronictlVersion ---"
            echo
            kubectl get pods -A -o wide | grep "NAME\|$c_name"
            other=$members
        else
            # Have a leader:
            echo "=== Looking at patronictl list info for the $c_name cluster \
with leader pod: $leader ==="
            
            other="$(echo $members | xargs -n 1 | grep -v $leader)"
            
            echo; echo "--- patronictl, version $patronictlVersion, list for $c_ns \
leader pod $leader ---"
            kubectl -n $c_ns exec $leader -- patronictl list 2>/dev/null
            kubectl get pods -A -o wide | grep "NAME\|$c_name"
            
            echo; echo "--- Logs for $c_ns \"Leader Pod\" $leader ---"
            kubectl logs -n $c_ns $leader postgres | \
                awk '{$1="";$2=""; print $line}' | egrep "INFO|ERROR" \
                | egrep -v "NewConnection|bootstrapping" | sort -u
        fi
        
        for o in $other
        do
            echo; echo "--- Logs for $c_ns$podDescribe pod $o ---"
            kubectl logs -n $c_ns $o postgres | awk '{$1="";$2=""; print $line}'\
                | egrep "INFO|ERROR" | egrep -v "NewConnection|bootstrapping" \
                | sort -u
        done
        echo;
        echo $dottedLine
        echo $dottedLine
        echo
done
echo "=== kubectl get pods -A -o wide | grep \"NAME\|postgres-\" |\
 grep -v \"operator\|Completed\|pooler\" ==="
echo
kubectl get pods -A -o wide | grep "NAME\|postgres-" | grep -v "operator\|Completed\|pooler"
echo
exit 0;

