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

# Function to check cray-sysmgmt-health chart with app version 9.3.1 for prometheus-operator and retain old PVs data.

function sysmgmt_health() {
    echo "Checking for chart version of cray-sysmgmt-health"
    version="45.1"
    if [ ! -z  "$(helm ls -o json --namespace sysmgmt-health| jq -r --argjson version $version '.[] | select(.app_version | sub(".[0-9]$";"") | tonumber | . < $version).name')" ]
    then
    prom_pvc="prometheus-cray-sysmgmt-health-promet-prometheus-db-prometheus-cray-sysmgmt-health-promet-prometheus-0"
    alert_pvc="alertmanager-cray-sysmgmt-health-promet-alertmanager-db-alertmanager-cray-sysmgmt-health-promet-alertmanager-0"
    echo "Get PV for both prometheus and Alertmanager"
    prom_pv=$(kubectl get pvc -n sysmgmt-health -o jsonpath='{.spec.volumeName}' $prom_pvc)
    alert_pv=$(kubectl get pvc -n sysmgmt-health -o jsonpath='{.spec.volumeName}' $alert_pvc)
    prom_pv="${prom_pv//[\",]}"
    alert_pv="${alert_pv//[\",]}"
    echo "Prometheus PV: $prom_pv"
    echo "Alertmanager PV: $alert_pv"

    # Patch the PersistenceVolume created/used by the prometheus-operator and alertmanager to Retain claim policy
    prom_pv_reclaim=$(kubectl get pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}' $prom_pv)
    alert_pv_reclaim=$(kubectl get pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}' $alert_pv)
    prom_pv_reclaim="${prom_pv_reclaim//[\",]}"
    alert_pv_reclaim="${alert_pv_reclaim//[\",]}"
    if [ "$prom_pv_reclaim" != Retain ] && [ "$alert_pv_reclaim" != Retain ]; then
        kubectl patch pv/$prom_pv -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
        kubectl patch pv/$alert_pv -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
    else
        echo "PVs persistentVolumeReclaimPolicy is already Retain"
    fi

    # Uninstall the cray-sysmgmt-health release
    helm ls -o json --namespace sysmgmt-health| jq -r --argjson version $version '.[] | select(.app_version | sub(".[0-9]$";"") | tonumber | . < $version).name'| xargs -L1 helm uninstall --namespace sysmgmt-health

    # Delete the existing PersistentVolumeClaim, and verify PV become Released.
    prom_pv_reclaim=$(kubectl get pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}' $prom_pv)
    alert_pv_reclaim=$(kubectl get pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}' $alert_pv)
    prom_pv_reclaim="${prom_pv_reclaim//[\",]}"
    alert_pv_reclaim="${alert_pv_reclaim//[\",]}"
    if [ "$prom_pv_reclaim" == Retain ] && [ "$alert_pv_reclaim" == Retain ]; then
        kubectl delete pvc/$prom_pvc -n sysmgmt-health
        kubectl delete pvc/$alert_pvc -n sysmgmt-health
        prom_pv_phase=$(kubectl get pv -o jsonpath='{.status.phase}' $prom_pv)
        alert_pv_phase=$(kubectl get pv -o jsonpath='{.status.phase}' $alert_pv)
        prom_pv_phase="${prom_pv_phase//[\",]}"
        alert_pv_phase="${alert_pv_phase//[\",]}"
        echo "Verifying whether PVs became Released or not."
        sleep 5
        if [ "$alert_pv_phase" == Released ] && [ "$prom_pv_phase" == Released ]; then
            echo "Both Prometheus and Alertmanager PVs are Released"
        else
           echo >&2 "PVs are not Released. Verify if PV exists or not."
           echo "Prometheus PV: $prom_pv"
           echo "Alertmanager PV: $alert_pv"
           exit
        fi

        # Remove the cray-sysmgmt-health-promet-kubelet service.
        echo "Deleting cray-sysmgmt-health-promet-kubelet service in kube-system namespace."
        kubectl delete service/cray-sysmgmt-health-promet-kubelet -n kube-system

        # Remove all the existing CRDs (ServiceMonitors, Podmonitors, etc.)
        echo "Deleting sysmgmt-health existing CRDs"
        for c in $(kubectl get crds -A -o jsonpath='{range .items[?(@.metadata.annotations.controller-gen\.kubebuilder\.io\/version=="v0.2.4")]}{.metadata.name}{"\n"}{end}'); do
          kubectl delete crd ${c}
        done
    else
       echo >&2 "PersistenceVolume created/used by the prometheus-operator and alertmanager is not Retain claim policy"
       echo >&2 "Exiting"
       exit
    fi
    
     # Remove current spec.claimRef values to change the PV's status from Released to Available.
    if [ "$alert_pv_phase" == Released ] && [ "$prom_pv_phase" == Released ]; then
        kubectl patch pv/$prom_pv --type json -p='[{"op": "remove", "path": "/spec/claimRef"}]'
        kubectl patch pv/$alert_pv --type json -p='[{"op": "remove", "path": "/spec/claimRef"}]'
        prom_pv_phase=$(kubectl get pv -o jsonpath='{.status.phase}' $prom_pv)
        alert_pv_phase=$(kubectl get pv -o jsonpath='{.status.phase}' $alert_pv)
        prom_pv_phase="${prom_pv_phase//[\",]}"
        alert_pv_phase="${alert_pv_phase//[\",]}"
        echo "Verifying whether PV became Available or not."
        sleep 5
        if [ "$alert_pv_phase" == Available ] && [ "$prom_pv_phase" == Available ]; then
            echo "Both Prometheus and Alertmanager PVs are Available. Ready to deploy the latest cray-sysmgmt-chart now."
        else
           echo >&2 "PVs are not Available. Verify if PV exists or not."
           echo "Prometheus PV: $prom_pv"
           echo "Alertmanager PV: $alert_pv"
           exit
        fi
    else
       echo "PV's status is not Released. Exiting"
       exit
    fi
fi
}

# sysmgmt_health function call

sysmgmt_health

                                         
