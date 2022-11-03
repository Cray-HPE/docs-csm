#!/bin/bash

# Copyright 2020-2021 Hewlett Packard Enterprise Development LP
#
# The ncnHealthChecks script executes a number of NCN system health checks:
#    Report Kubernetes status for Master and worker nodes
#    Report Ceph health status
#    Report health of Etcd clusters in services namespace
#    Report the number of pods on which worker node for each Etcd cluster
#    Report any "alarms" set for any of the Etcd clusters
#    Report health of Etcd cluster's database
#    List automated Etcd backups for BOS, BSS, CRUS, DNS and FAS
#    Report ncn node uptimes
#    Report NCN master and worker node resource consumption
#    Report NCN node xnames and metal.no-wipe status
#    Report worker ncn node pod counts
#    Report pods yet to reach the running state
#
# Returned results are not verified. Information is provided to aide in
# analysis of the results.
#
# The ncnHealthChecks script can be run on any worker or master NCN node from
# any directory. The ncnHealthChecks script can be run before and after an
# NCN node is rebooted.
#

function get_token() {
  cnt=0
  TOKEN=""
  endpoint="https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token"
  client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d)
  while [ "$TOKEN" == "" ]; do
    cnt=$((cnt+1))
    TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$client_secret $endpoint)
    if [[ "$TOKEN" == *"error"* ]]; then
      TOKEN=""
      if [ "$cnt" -eq 5 ]; then
        break
      fi
    else
      TOKEN=$(echo $TOKEN | jq -r '.access_token')
      break
    fi
  done
  echo $TOKEN
}

echo "             +++++ NCN Health Checks +++++"
echo "=== Can be executed on any worker or master ncn node. ==="
hostName=$(hostname)
echo "=== Executing on $hostName, $(date) ==="

sshOptions="-q -o StrictHostKeyChecking=no"

# Get master nodes:
mNcnNodes=$(kubectl get nodes --selector='node-role.kubernetes.io/master' \
                    --no-headers=true | awk '{print $1}' | tr "\n", " ")

# Get worker nodes:
wNcnNodes=$(kubectl get node --selector='!node-role.kubernetes.io/master' \
                    --no-headers=true | awk '{print $1}' | tr "\n", " ")

# Get first master node - should not be the PIT node:
firstMaster=$(echo $mNcnNodes | awk '{print $1}')

# Get storage nodes:
sNcnNodes=$(ssh $sshOptions $firstMaster ceph node ls osd | \
                 jq -r 'keys | join(" ")')

# Get first storage node:
firstStorage=$(echo $sNcnNodes | awk '{print $1}')

ncnNodes=${mNcnNodes}${wNcnNodes}$sNcnNodes
echo "=== NCN Master nodes: ${mNcnNodes}==="
echo "=== NCN Worker nodes: ${wNcnNodes}==="
echo "=== NCN Storage nodes: $sNcnNodes ==="

echo
echo "=== Check Kubernetes' Master and Worker Node Status. ==="
echo "=== Verify Kubernetes' Node \"Ready\" Status and Version. ==="
date
kubectl get nodes -o wide
echo

echo
echo "=== Check Ceph Health Status. ==="
echo "=== Verify \"health: HEALTH_OK\" Status. ==="
echo "=== At times a status of HEALTH_WARN, too few PGs per OSD, and/or large \
omap objects, may be okay. ==="
echo "=== date; ssh $firstStorage ceph -s; ==="
date
ssh $sshOptions $firstStorage ceph -s

# Set a delay of 15 seconds for use with timeout command:
Delay=15
echo
echo "=== Check the Health of the Etcd Clusters in the Services Namespace. ==="
echo "=== Verify a \"healthy\" Report for Each Etcd Pod. ==="
date;
for pod in $(kubectl get pods -l app=etcd -n services \
		     -o jsonpath='{.items[*].metadata.name}')
do
    echo "### ${pod} ###"
    timeout $Delay kubectl -n services exec ${pod} -- /bin/sh -c \
            "ETCDCTL_API=3 etcdctl endpoint health"; if [[ $? -ne 0 ]]; \
            then echo "FAILED - Pod Not Healthy"; fi
done
echo

echo
echo "=== Check the Number of Pods in Each Cluster. Verify they are Balanced. ==="
echo "=== Each cluster should contain at least three pods, but may contain more. ==="
echo "=== Ensure that no two pods in a given cluster exist on the same worker node. ==="
date
for ns in services
do
    for cluster in $(kubectl get etcdclusters.etcd.database.coreos.com \
                             -n $ns | grep -v NAME | awk '{print $1}')
    do
        kubectl get pod -n $ns -o wide | grep $cluster; echo ""
    done
done

echo
echo "=== Check if any \"alarms\" are set for any of the Etcd Clusters in the \
Services Namespace. ==="
echo "=== An empty list is returned if no alarms are set ==="
for pod in $(kubectl get pods -l app=etcd -n services \
                     -o jsonpath='{.items[*].metadata.name}')
do
    echo "### ${pod} Alarms Set: ###"
    timeout $Delay kubectl -n services exec ${pod} -- /bin/sh \
            -c "ETCDCTL_API=3 etcdctl alarm list"; if [[ $? -ne 0 ]];\
            then echo "FAILED - Pod Not Healthy"; fi
done
echo

echo
echo "=== Check the health of Etcd Cluster's database in the Services Namespace. ==="
echo "=== PASS or FAIL status returned. ==="
for pod in $(kubectl get pods -l app=etcd -n services \
                     -o jsonpath='{.items[*].metadata.name}')
do
    echo "### ${pod} Etcd Database Check: ###"
    dbc=$(timeout  --preserve-status --foreground $Delay kubectl \
                   -n services exec ${pod} -- /bin/sh \
                   -c "ETCDCTL_API=3 etcdctl put foo fooCheck && \
                   ETCDCTL_API=3 etcdctl get foo && \
                   ETCDCTL_API=3 etcdctl del foo && \
                   ETCDCTL_API=3 etcdctl get foo" 2>&1)
    echo $dbc | awk '{ if ( $1=="OK" && $2=="foo" && \
                       $3=="fooCheck" && $4=="1" && $5=="" ) print \
    "PASS:  " PRINT $0;
    else \
    print "FAILED DATABASE CHECK - EXPECTED: OK foo fooCheck 1 \
    GOT: " PRINT $0 }'
done
echo

echo
echo "=== List automated etcd backups on system. ==="
echo "=== Etcd Clusters with Automatic Etcd Back-ups Configured: ==="
echo "=== BOS, BSS, CRUS, DNS and FAS ==="
echo "=== May want to ensure that automated back-ups are up to-date ==="
echo "=== and that automated back-ups continue after NCN worker reboot. ==="
echo "=== Clusters without Automated Backups: ==="
echo "=== HBTD, HMNFD, REDS, UAS & CPS ==="
echo "=== Automatic backups generated after cluster has been running 24 hours. ==="
echo "=== date; kubectl exec -it -n operators \$(kubectl get pod -n operators \
| grep etcd-backup-restore | head -1 | awk '{print \$1}') -c boto3 -- \
list_backups \"\"; ==="
date
kubectl exec -it -n operators $(kubectl get pod -n operators | \
grep etcd-backup-restore | head -1 | awk '{print $1}') -c boto3 -- list_backups ""
date
echo

echo
echo "=== NCN node uptimes ==="
echo "=== NCN Master nodes: ${mNcnNodes}==="
echo "=== NCN Worker nodes: ${wNcnNodes}==="
echo "=== NCN Storage nodes: $sNcnNodes ==="
echo "=== date; for n in $ncnNodes; do echo\
 "\$n:"; ssh \$n uptime; done ==="
date;
for n in $ncnNodes
do
    echo "$n:";
    ssh $sshOptions $n uptime;
done
echo

echo
echo "=== NCN master and worker node resource consumption ==="
echo "=== NCN Master nodes: ${mNcnNodes}==="
echo "=== NCN Worker nodes: ${wNcnNodes}==="
echo "=== date; kubectl top nodes ==="
date;
kubectl top nodes
echo

echo
echo "=== NCN node xnames and metal.no-wipe status ==="
echo "=== metal.no-wipe=1, expected setting - the client ==="
echo "=== already has the right partitions and a bootable ROM. ==="
echo "=== Note that before the PIT node has been rebooted into ncn-m001, ==="
echo "=== metal.no-wipe status may not available. ==="
echo "=== NCN Master nodes: ${mNcnNodes}==="
echo "=== NCN Worker nodes: ${wNcnNodes}==="
echo "=== NCN Storage nodes: $sNcnNodes ==="
# Get token:
export TOKEN=$(get_token)
if [[ -z $TOKEN ]]
then
    echo "Failed to get token, skipping metal.no-wipe checks. "
fi
date;
for ncn_i in $ncnNodes
do
    echo -n "$ncn_i: "
    xName=$(ssh $sshOptions $ncn_i 'cat /etc/cray/xname')
    if [[ -z $xName ]]
    then
        echo "Failed to obtain xname for $ncn_i"
        continue;
    fi
    if [[ $ncn_i == "ncn-m001" ]]
    then
        macAddress=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootscript?name=${xName}" | grep chain)
        macAddress=${macAddress#*mac=}
        macAddress=${macAddress%&arch*}
        noWipe=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootscript?mac=${macAddress}&arch=x86" | grep -o metal.no-wipe=[01])
    else
        noWipe=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootscript?name=${xName}" | grep -o metal.no-wipe=[01])
    fi
    echo "$xName - $noWipe"
done
echo

echo
echo "=== Worker ncn node pod counts ==="
echo "=== NCN Worker nodes: ${wNcnNodes}==="
echo "=== date; kubectl get pods -A -o wide | grep -v Completed | grep ncn-XXX \
| wc -l ==="
date;
for n in $wNcnNodes
do
    echo -n "$n: ";
    kubectl get pods -A -o wide | grep -v Completed | grep $n | wc -l;
done
echo

echo
echo "=== Pods yet to reach the running state: ==="
echo "=== kubectl get pods -A -o wide | grep -v \"Completed\|Running\" ==="
date
kubectl get pods -A -o wide | grep -v "Completed\|Running"
echo
echo
