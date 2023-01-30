#!/usr/bin/env sh
#
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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
cwd=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
set -eu

# We expect this to look like:
# NAME                        READY   STATUS    RESTARTS   AGE
# cray-shared-kafka-kafka-0   1/1     Running   0          3m16s
# cray-shared-kafka-kafka-1   1/1     Running   0          22s
# cray-shared-kafka-kafka-2   1/1     Running   0          4m18s

# Not:
# NAME                        READY   STATUS    RESTARTS   AGE
# cray-shared-kafka-kafka-0   2/2     Running   0          3h57m
# cray-shared-kafka-kafka-1   2/2     Running   0          3h56m
# cray-shared-kafka-kafka-2   2/2     Running   0          3h55m
podsready() {
    [ "1/1" = "$(kubectl get pods --no-headers=true --namespace services --selector strimzi.io/name=cray-shared-kafka-kafka --field-selector=status.phase=Running | awk '!/READY/ {print $2}' | sort -u)" ] &&
	[ "Running" = "$(kubectl get pods --no-headers=true --namespace services --selector strimzi.io/name=cray-shared-kafka-kafka | awk '{print $3}' | sort -u)" ]
}

kafkaok() {
    ok='[{"name":"plain","port":9092,"tls":false,"type":"internal"}]'
    [ "${ok}" = "$(kubectl get kafka cluster -n sma -o=jsonpath='{.spec.kafka.listeners}')" ]
}

# Ensure we don't do anything if we're run without the resource in question
if ! kubectl get kafka cluster --namespace sma > /dev/null 2>&1; then
    printf "No kafka cluster resource found, nothing for this script to do\n" >&2
    exit 0
fi

# Logic loop is loop/retrying things in order until ok, tries for 300 seconds
# total and after that gives up, can be re-run.
start=$(date +%s)
until kafkaok && podsready; do
    now=$(date +%s)
    if [ $((now - start)) -ge 300 ]; then
	printf "Giving up trying to restart kafka pods after 5 minutes\n" >&2
	exit 1
    fi

    if ! kafkaok; then
	printf "Patching kafka cluster resource to include listeners\n" >&2
	kubectl patch kafka cluster --namespace sma --type merge --patch-file "${cwd}/patch-listeners.yaml"
	sleep 10
    fi

    if ! podsready; then
	printf "Found pods not at Ready = 1/1, deleting to force an update\n" >&2
	for pod in $(kubectl get pods --no-headers=true --namespace services --selector strimzi.io/name=cray-shared-kafka-kafka --field-selector="status.phase=Running" | awk '!/1\/1/ {print $1}'); do
	    printf "Deleting %s\n" "${pod}" >&2
	    kubectl delete --namespace services pod "$pod"
	    sleep 10
	done
    fi
    printf "Sleeping for reconciliation\n" >&2
    sleep 30
done

printf "Ok to continue\n" >&2
