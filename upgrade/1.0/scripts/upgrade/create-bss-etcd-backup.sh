#!/bin/bash

upgrade_ncn=$1
timestamp=$(date +"%s")

backup_name=$(kubectl exec -it -n operators $(kubectl get pod -n operators | grep etcd-backup-restore | head -1 | awk '{print $1}') -c util -- create_backup cray-bss upgrade-${upgrade_ncn}-${timestamp} | grep etcdbackup | awk '{print $1}' | cut -d '/' -f2 )
successful_backup=$(kubectl -n services get etcdbackup $backup_name -o jsonpath='{.status.succeeded}')
if [[ $successful_backup != 'true' ]]
then
    sleep 3
    successful_backup=$(kubectl -n services get etcdbackup $backup_name -o jsonpath='{.status.succeeded}')
    if [[ $successful_backup != 'true' ]]; then echo "Unsuccessful bss-etcd backup during $upgrade_ncn upgrade at timestamp: $timestamp"; fi
fi

