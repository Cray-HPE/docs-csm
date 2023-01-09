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

TMPDIR=$(mktemp -d)

# usage returns the usage
usage() {
	echo "
Usage:

$0 [enable | disable ]

enable  - enable component name (xname) validation on the OPA gateway
disable - disable component name (xname) validation on the OPA gateway
"
}

# backup_customizations saves a yaml version of the customizations secret to a
# tmp directory
backup_customizations() {
	kubectl get secrets -n loftsman site-init -o yaml >"${TMPDIR}/site-init.yaml"
	echo "Backup copy of the site-init secret has been saved to ${TMPDIR}/site-init.yaml"

}

# get_customizations saves the customizations file from the customizations secret
# to tmp directory
get_customizations() {
	kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d >"${TMPDIR}/customizations.yaml"
}

# enable_xnameValidation_in_charts uses yq to enable xname validation in
# customizations.yaml
enable_xname_in_charts() {
	yq w -i "${TMPDIR}/customizations.yaml" -- 'spec.kubernetes.services.cray-opa.opa.xnamePolicy.bos' 'true'
	yq w -i "${TMPDIR}/customizations.yaml" -- 'spec.kubernetes.services.cray-opa.opa.xnamePolicy.cfs' 'true'
	yq w -i "${TMPDIR}/customizations.yaml" -- 'spec.kubernetes.services.cray-opa.opa.xnamePolicy.ckdump' 'true'
	yq w -i "${TMPDIR}/customizations.yaml" -- 'spec.kubernetes.services.cray-opa.opa.xnamePolicy.dvs' 'true'
	yq w -i "${TMPDIR}/customizations.yaml" -- 'spec.kubernetes.services.cray-opa.opa.xnamePolicy.heartbeat' 'true'
	yq w -i "${TMPDIR}/customizations.yaml" -- 'spec.kubernetes.services.cray-opa.opa.xnamePolicy.enabled' 'true'
	yq w -i "${TMPDIR}/customizations.yaml" -- 'spec.kubernetes.services.spire.server.tokenService.enableXNameWorkloads' 'true'
}

# disable_xnameValidation_in_charts uses yq to disable xname validation in
# customizations.yaml
disable_xname_in_charts() {
	yq w -i "${TMPDIR}/customizations.yaml" -- 'spec.kubernetes.services.cray-opa.opa.xnamePolicy.bos' 'false'
	yq w -i "${TMPDIR}/customizations.yaml" -- 'spec.kubernetes.services.cray-opa.opa.xnamePolicy.cfs' 'false'
	yq w -i "${TMPDIR}/customizations.yaml" -- 'spec.kubernetes.services.cray-opa.opa.xnamePolicy.ckdump' 'false'
	yq w -i "${TMPDIR}/customizations.yaml" -- 'spec.kubernetes.services.cray-opa.opa.xnamePolicy.dvs' 'false'
	yq w -i "${TMPDIR}/customizations.yaml" -- 'spec.kubernetes.services.cray-opa.opa.xnamePolicy.heartbeat' 'false'
	yq w -i "${TMPDIR}/customizations.yaml" -- 'spec.kubernetes.services.cray-opa.opa.xnamePolicy.enabled' 'false'
	yq w -i "${TMPDIR}/customizations.yaml" -- 'spec.kubernetes.services.spire.server.tokenService.enableXNameWorkloads' 'false'
}

# create_manifest creates the xname manifest with the cray-opa and spire information from
# the manifests that ship with CSM. After this it will use manifestgen to create a manifest.yaml
# to use with loftsman
create_manifest() {
	yq m -a append "${PWD}/manifests/sysmgmt.yaml" "${PWD}/manifests/platform.yaml" >"${TMPDIR}/xnamevalidation.yaml"
	yq w -i "${TMPDIR}/xnamevalidation.yaml" "metadata.name" "xnamevalidation"

	for chart in $(yq r "${TMPDIR}/xnamevalidation.yaml" 'spec.charts[*].name' | grep -Ev '(^cray-opa$|^spire$)'); do
		yq d -i "${TMPDIR}/xnamevalidation.yaml" 'spec.charts(name=='"$chart"')'
	done

	manifestgen -c "${TMPDIR}/customizations.yaml" -i "${TMPDIR}/xnamevalidation.yaml" -o "${TMPDIR}/manifest.yaml"
}

# update_customizations saves the updated customizations file back to the
# site-init secret
update_customizations() {
	CUSTOMIZATIONS="$(base64 <"${TMPDIR}/customizations.yaml" | tr -d '\n')"
	kubectl get secrets -n loftsman site-init -o json |
		jq ".data.\"customizations.yaml\" |= \"$CUSTOMIZATIONS\"" | kubectl apply -f -
}

# run_loftsman runs loftsman against our trimmed down manifest file to enable
# xname validation in the cray-opa and spire charts
run_loftsman() {
	loftsman ship --charts-path "${PWD}/helm" --manifest-path "${TMPDIR}/manifest.yaml"

	# Restart opa pods so that the policy changes are picked up
	kubectl rollout restart -n opa deployment cray-opa-ingressgateway
	kubectl rollout restart -n opa deployment cray-opa-ingressgateway-customer-admin
	kubectl rollout restart -n opa deployment cray-opa-ingressgateway-customer-user
}

# validate_prereqs makes sure everything is available for this script to work
validate_prereqs() {
	# validate site-init secret exists
	if ! kubectl get secret -n loftsman site-init >/dev/null 2>&1; then
		echo "Error: missing site-init secret in loftsman namespace."
		exit 3
	fi

	# validate that cray-opa is included in platform.yaml
	if ! yq r "${PWD}/manifests/platform.yaml" 'spec.charts(name==cray-opa)' | grep -q cray-opa; then
		echo "The cray-opa chart is missing from ${PWD}/manifests/platform.yaml"
		exit 3
	fi

	# validate that spire is included in sysmgmt.yaml
	if ! yq r "${PWD}/manifests/sysmgmt.yaml" 'spec.charts(name==spire)' | grep -q spire; then
		echo "The spire chart is missing from ${PWD}/manifests/sysmgmt.yaml"
		exit 3
	fi

	# validate helm chart exists
	if ! [ -d "$PWD/helm" ]; then
		echo "Error: $PWD/helm is missing. Make sure you run this from the extracted CSM tar file"
		exit 3
	fi

	# validate loftsman exists
	if ! which loftsman >/dev/null; then
		echo "Error: loftsman binary missing from path."
		exit 3
	fi

	# validate manifestgen exists
	if ! which manifestgen >/dev/null; then
		echo "Error: manifestgen binary missing from path."
		exit 3
	fi

	# validate yq
	if ! which yq >/dev/null; then
		echo "Error: yq binary missing from path."
		exit 3
	elif ! yq -V | grep -q 'yq version 3'; then
		echo "Error: unsupported version of yq. This script requires yq 3"
		exit 3
	fi
}

wait_for_spire() {
	RETRY=0
	MAX_RETRIES=30
	RETRY_SECONDS=30
	until kubectl get -n spire statefulset spire-server | grep -q '3/3'; do
		if [[ $RETRY -lt $MAX_RETRIES ]]; then
			RETRY="$((RETRY + 1))"
			echo "spire-server is not ready. Will retry after $RETRY_SECONDS seconds. ($RETRY/$MAX_RETRIES)"
		else
			echo "spire-server did not start after $(echo "$RETRY_SECONDS" \* "$MAX_RETRIES" | bc) seconds."
			exit 1
		fi
		sleep "$RETRY_SECONDS"
	done
}

validate_disable() {
	if [ "$(helm get values -n spire spire -o json | jq -r '.server.tokenService.enableXNameWorkloads')" = "true" ]; then
		echo "component name (xname) validation is already enabled"
		exit 1
	fi
}

validate_enable() {
	if [ ! "$(helm get values -n spire spire -o json | jq -r '.server.tokenService.enableXNameWorkloads')" = "true" ]; then
		echo "component name (xname) validation is already disabled"
		exit 1
	fi
}

function sshnh() {
	/usr/bin/ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" "$@"
}

disable_spire_on_NCNs() {
	echo "Stopping spire on NCNs"
	storageNodes=$(ceph node ls | jq -r '.[] | keys[]' | sort -u)
	ncnNodes=$(kubectl get nodes -o name | cut -d'/' -f2)

	for node in $storageNodes $ncnNodes; do
		sshnh "$node" systemctl stop spire-agent
		sshnh "$node" rm -f /root/spire/data/svid.key /root/spire/bundle.der /root/spire/agent_svid.der
	done

}

enable_spire_on_NCNs() {
	echo "Enabling spire on NCNs"
	ncnNodes=$(kubectl get nodes -o name | cut -d'/' -f2)

	for node in $ncnNodes; do
		sshnh "$node" systemctl start spire-agent
	done

	/opt/cray/platform-utils/spire/fix-spire-on-storage.sh
}

uninstall_spire() {
	echo "Uninstalling spire"
	helm uninstall -n spire spire
	while ! [ "$(kubectl get pods -n spire --no-headers | wc -l)" -eq 0 ]; do
		echo "Waiting for all spire pods to be terminated."
		sleep 30
	done

	echo "Removing spire-server PVCs"
	for pvc in $(kubectl get pvc -n spire --no-headers -o custom-columns=":metadata.name"); do
		kubectl delete pvc -n spire "$pvc"
	done
}

enable_xnameValidation() {
	validate_prereqs
	validate_disable
	backup_customizations
	get_customizations
	enable_xname_in_charts
	create_manifest
	disable_spire_on_NCNs
	uninstall_spire
	run_loftsman
	update_customizations
	wait_for_spire
	enable_spire_on_NCNs
	echo "component name (xname) validation has been enabled."
}

disable_xnameValidation() {
	validate_prereqs
	validate_enable
	backup_customizations
	get_customizations
	disable_xname_in_charts
	create_manifest
	disable_spire_on_NCNs
	uninstall_spire
	run_loftsman
	update_customizations
	wait_for_spire
	enable_spire_on_NCNs
	echo "component name (xname) validation has been disabled."
}

# Main
if [ "$#" -lt 1 ]; then
	usage
	exit 1
elif [ "$1" = enable ]; then
	enable_xnameValidation
elif [ "$1" = "disable" ]; then
	disable_xnameValidation
else
	usage
	exit 2
fi
