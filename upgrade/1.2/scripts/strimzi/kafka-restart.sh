#!/bin/bash
set -euo pipefail

for pod in $(kubectl get pods -n services -oname | grep kafka-kafka); do
	echo "Deleting $pod"
	kubectl delete -n services "$pod"
	sleep 10
	while ! kubectl get -n services "$pod" -o json | jq -r '.status.phase' | grep -q 'Running'; do
		echo "Waiting for $pod to start"
		sleep 10
	done
	echo "Waiting 30 seconds before continuing"
	sleep 30
done
