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
set -euo pipefail

echo "Updating CRDs to 0.22.0"
for i in crds/*; do
	kubectl replace -f "$i" || kubectl create -f "$i"
done

echo "Patching kafka topics to be managed by helm"
for i in $(kubectl get -n services kafkatopics | awk '{print $1}' | tail -n+2); do
	kubectl annotate -n services kafkatopics.kafka.strimzi.io "$i" 'meta.helm.sh/release-name=cray-shared-kafka' --overwrite=true
	kubectl annotate -n services kafkatopics.kafka.strimzi.io "$i" 'meta.helm.sh/release-namespace=services' --overwrite=true
	kubectl label -n services kafkatopics.kafka.strimzi.io "$i" 'app.kubernetes.io/managed-by=Helm' --overwrite=true
done

for secret in $(kubectl get secrets -n operators -oname | grep sh.helm.release.v1.cray-kafka-operator | cut -d/ -f2); do
	echo "Backing up helm release cray-kafka-operator secret to /tmp/$secret.yaml"
	kubectl get secret -n operators "$secret" -o yaml >/tmp/"$secret".yaml

	echo "Removing helm secret $secret"
	kubectl delete secret -n operators "$secret"
done

echo "Creating a snapshot file in zookeeper if one does not already exist"
for i in $(kubectl get pods -A | grep zookeeper | awk '{print $1":"$2}'); do
	if ! kubectl exec -n "${i%:*}" "${i#*:}" -c zookeeper -- ls /var/lib/zookeeper/data/version-2 | grep -q 'snapshot'; then
		echo "Creating snapshot for ${i/://}"
		kubectl cp snapshot.0 "${i/://}":/var/lib/zookeeper/data/version-2/snapshot.0 -c zookeeper
	fi
done
