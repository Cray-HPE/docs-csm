#!/bin/bash
set -euo pipefail

TMPDIR=$(mktemp -d)
TRUSTDOMAIN=$(kubectl get pod -n spire spire-server-0 -o json | jq -r '.spec.containers[].env[]| select(.name=="SPIRE_DOMAIN") | .value')

# usage returns the usage
usage() {
	echo "
Usage:

$0 [enable | disable ]

enable  - enables xname validation on the OPA gateway
disable - disables xname validation on the OPA gateway
"
}

# get_tenants gets a list of tenants by querying the postgres server. This cannot
# be done via the spire-server binary, as it will fail to return data once there
# are a large number of entries.
get_tenants() {
	kubectl exec -itn spire spire-postgres-0 --container postgres -- su postgres -c "psql spire -c \"SELECT spiffe_id FROM registered_entries where spiffe_id LIKE '%tenant1%'\" -P "tuples_only" -P "pager 0"" | sort -u
}

# get_tenants_by_type returns a tenant of a specific type, which can be more easily
# used in a for loop
get_tenants_by_type() {
	type="$1"
	get_tenants | grep "$type/tenant1"
}

# add_xname_workload_entry takes an xname, type, workload, and optionally a ttl and
# creates a spire entry if it doesn't already exist
add_xname_workload_entry() {
	tenant="$1"
	type="$2"
	workload="$3"
	agentPath="$4"

	xname="${tenant##*/}"

	if ! kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -spiffeID "spiffe://shasta/${type}/${xname}/workload/${workload}" | grep -q "spiffe://shasta/${type}/${xname}/workload/${workload}"; then
		if [ "$#" -eq 5 ]; then
			ttl="$5"
			kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server entry create \
				-parentID "$tenant" \
				-spiffeID "spiffe://${TRUSTDOMAIN}/${type}/${xname}/workload/${workload}" \
				-selector unix:uid:0 \
				-selector unix:gid:0 \
				-selector "unix:path:${agentPath}" \
				-ttl "${ttl}" || echo "Entry creation failed: $*"
		else
			kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server entry create \
				-parentID "$tenant" \
				-spiffeID "spiffe://${TRUSTDOMAIN}/${type}/${xname}/workload/${workload}" \
				-selector unix:uid:0 \
				-selector unix:gid:0 \
				-selector "unix:path:${agentPath}" || echo "Entry creation failed: $*"
		fi
	else
		echo "Entry already exists: $*"
	fi
}

# add_regular_workload_entry takes an xname, type, workload, and optionally a ttl and
# creates a spire entry if it doesn't already exist
add_regular_workload_entry() {
	type="$1"
	workload="$2"
	agentPath="$3"

	if ! kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -spiffeID "spiffe://shasta/${type}/workload/${workload}" | grep -q "spiffe://shasta/${type}/workload/${workload}"; then
		if [ "$#" -eq 4 ]; then
			ttl="$4"
			kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server entry create \
				-parentID "spiffe://shasta/$type" \
				-spiffeID "spiffe://${TRUSTDOMAIN}/${type}/workload/${workload}" \
				-selector unix:uid:0 \
				-selector unix:gid:0 \
				-selector "unix:path:${agentPath}" \
				-ttl "${ttl}" || echo "Entry creation failed: $*"
		else
			kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server entry create \
				-parentID "spiffe://shasta/$type" \
				-spiffeID "spiffe://${TRUSTDOMAIN}/${type}/workload/${workload}" \
				-selector unix:uid:0 \
				-selector unix:gid:0 \
				-selector "unix:path:${agentPath}" || echo "Entry creation failed: $*"
		fi
	else
		echo "Entry already exists: $*"
	fi
}
# delete_workload_entry finds a workload entry and removes it if it exists
delete_workload_entry() {
	spiffeID="$1"

	if kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -spiffeID "$spiffeID" | grep -q "Entry ID"; then
		# For some reason, this command has a ^M at the end. the tr command strips this out.
		for entryID in $(kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -spiffeID "$spiffeID" | grep "Entry ID" | awk '{print $4}' | tr -d "\015"); do
			kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server entry delete -entryID "${entryID}"
		done
	fi
}

# delete_workloads_for_tenant takes a tenant and will delete all workloads that
# are associated with that tenant
delete_workloads_for_tenant() {
	tenant="$1"

	if kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -parentID "$tenant" | grep -q "Entry ID"; then
		# For some reason, this command has a ^M at the end. the tr command strips this out.
		for entryID in $(kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -parentID "$tenant" | grep "Entry ID" | awk '{print $4}' | tr -d "\015"); do
			# Only delete entries where the SPIFFE ID contains the string workload
			if kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -entryID "${entryID}" | grep "SPIFFE ID" | grep -q workload; then
				kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server entry delete -entryID "$entryID"
			fi
		done
	fi
}

# delete_spiffeID takes a spiffeID and deletes it if it exists
delete_spiffeID() {
	spiffeID="$1"

	if kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -spiffeID "$spiffeID" | grep -q "Entry ID"; then
		# For some reason, this command has a ^M at the end. the tr command strips this out.
		for entryID in $(kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -spiffeID "$spiffeID" | grep "Entry ID" | awk '{print $4}' | tr -d "\015"); do
			kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server entry delete -entryID "$entryID"
		done
	fi
}

# add_xname_workloads adds all the xname validaton workloads that are used in
# CSM 1.2 to each spire client
add_xname_workloads() {

	# Add workloads for existing NCNs
	for tenant in $(get_tenants_by_type ncn | tr -d "\015"); do
		add_xname_workload_entry "$tenant" ncn bos-state-reporter /usr/bin/bos-state-reporter-spire-agent
		add_xname_workload_entry "$tenant" ncn cfs-state-reporter /usr/bin/cfs-state-reporter-spire-agent
		add_xname_workload_entry "$tenant" ncn cpsmount /usr/bin/cpsmount-spire-agent
		add_xname_workload_entry "$tenant" ncn cpsmount_helper /opt/cray/cps-utils/bin/cpsmount_helper
		add_xname_workload_entry "$tenant" ncn dvs-hmi /usr/bin/dvs-hmi-spire-agent
		add_xname_workload_entry "$tenant" ncn dvs-map /usr/bin/dvs-map-spire-agent
		add_xname_workload_entry "$tenant" ncn heartbeat /usr/bin/heartbeat-spire-agent
		add_xname_workload_entry "$tenant" ncn orca /usr/bin/orca-spire-agent
	done

	# Add workloads for existing Computes
	for tenant in $(get_tenants_by_type compute | tr -d "\015"); do
		add_xname_workload_entry "$tenant" compute bos-state-reporter /usr/bin/bos-state-reporter-spire-agent
		add_xname_workload_entry "$tenant" compute cfs-state-reporter /usr/bin/cfs-state-reporter-spire-agent
		add_xname_workload_entry "$tenant" compute ckdump /usr/bin/ckdump-spire-agent 864000
		add_xname_workload_entry "$tenant" compute ckdump_helper /usr/sbin/ckdump_helper 864000
		add_xname_workload_entry "$tenant" compute cpsmount /usr/bin/cpsmount-spire-agent
		add_xname_workload_entry "$tenant" compute cpsmount_helper /opt/cray/cps-utils/bin/cpsmount_helper
		add_xname_workload_entry "$tenant" compute dvs-hmi /usr/bin/dvs-hmi-spire-agent
		add_xname_workload_entry "$tenant" compute dvs-map /usr/bin/dvs-map-spire-agent
		add_xname_workload_entry "$tenant" compute heartbeat /usr/bin/heartbeat-spire-agent
		add_xname_workload_entry "$tenant" compute orca /usr/bin/orca-spire-agent
		add_xname_workload_entry "$tenant" compute wlm /usr/bin/wlm-spire-agent
	done

	# Add workloads for existing Storage nodes
	for tenant in $(get_tenants_by_type storage | tr -d "\015"); do
		add_xname_workload_entry "$tenant" storage cfs-state-reporter /usr/bin/cfs-state-reporter-spire-agent
	done

	# Add workloads for existing UANs
	for tenant in $(get_tenants_by_type uan | tr -d "\015"); do
		add_xname_workload_entry "$tenant" uan bos-state-reporter /usr/bin/bos-state-reporter-spire-agent
		add_xname_workload_entry "$tenant" uan cfs-state-reporter /usr/bin/cfs-state-reporter-spire-agent
		add_xname_workload_entry "$tenant" uan ckdump /usr/bin/ckdump-spire-agent 864000
		add_xname_workload_entry "$tenant" uan ckdump_helper /usr/sbin/ckdump_helper 864000
		add_xname_workload_entry "$tenant" uan cpsmount /usr/bin/cpsmount-spire-agent
		add_xname_workload_entry "$tenant" uan cpsmount_helper /opt/cray/cps-utils/bin/cpsmount_helper
		add_xname_workload_entry "$tenant" uan dvs-hmi /usr/bin/dvs-hmi-spire-agent
		add_xname_workload_entry "$tenant" uan dvs-map /usr/bin/dvs-map-spire-agent
		add_xname_workload_entry "$tenant" uan heartbeat /usr/bin/heartbeat-spire-agent
		add_xname_workload_entry "$tenant" uan orca /usr/bin/orca-spire-agent
	done
}

# add_regular_workloads adds all the regular workloads that are used in CSM 1.2
add_regular_workloads() {

	add_regular_workload_entry ncn bos-state-reporter /usr/bin/bos-state-reporter-spire-agent
	add_regular_workload_entry ncn cfs-state-reporter /usr/bin/cfs-state-reporter-spire-agent
	add_regular_workload_entry ncn cpsmount /usr/bin/cpsmount-spire-agent
	add_regular_workload_entry ncn cpsmount_helper /opt/cray/cps-utils/bin/cpsmount_helper
	add_regular_workload_entry ncn dvs-hmi /usr/bin/dvs-hmi-spire-agent
	add_regular_workload_entry ncn dvs-map /usr/bin/dvs-map-spire-agent
	add_regular_workload_entry ncn heartbeat /usr/bin/heartbeat-spire-agent
	add_regular_workload_entry ncn orca /usr/bin/orca-spire-agent

	add_regular_workload_entry compute bos-state-reporter /usr/bin/bos-state-reporter-spire-agent
	add_regular_workload_entry compute cfs-state-reporter /usr/bin/cfs-state-reporter-spire-agent
	add_regular_workload_entry compute ckdump /usr/bin/ckdump-spire-agent 864000
	add_regular_workload_entry compute ckdump_helper /usr/sbin/ckdump_helper 864000
	add_regular_workload_entry compute cpsmount /usr/bin/cpsmount-spire-agent
	add_regular_workload_entry compute cpsmount_helper /opt/cray/cps-utils/bin/cpsmount_helper
	add_regular_workload_entry compute dvs-hmi /usr/bin/dvs-hmi-spire-agent
	add_regular_workload_entry compute dvs-map /usr/bin/dvs-map-spire-agent
	add_regular_workload_entry compute heartbeat /usr/bin/heartbeat-spire-agent
	add_regular_workload_entry compute orca /usr/bin/orca-spire-agent
	add_regular_workload_entry compute wlm /usr/bin/wlm-spire-agent

	add_regular_workload_entry storage cfs-state-reporter /usr/bin/cfs-state-reporter-spire-agent

	add_regular_workload_entry uan bos-state-reporter /usr/bin/bos-state-reporter-spire-agent
	add_regular_workload_entry uan cfs-state-reporter /usr/bin/cfs-state-reporter-spire-agent
	add_regular_workload_entry uan ckdump /usr/bin/ckdump-spire-agent 864000
	add_regular_workload_entry uan ckdump_helper /usr/sbin/ckdump_helper 864000
	add_regular_workload_entry uan cpsmount /usr/bin/cpsmount-spire-agent
	add_regular_workload_entry uan cpsmount_helper /opt/cray/cps-utils/bin/cpsmount_helper
	add_regular_workload_entry uan dvs-hmi /usr/bin/dvs-hmi-spire-agent
	add_regular_workload_entry uan dvs-map /usr/bin/dvs-map-spire-agent
	add_regular_workload_entry uan heartbeat /usr/bin/heartbeat-spire-agent
	add_regular_workload_entry uan orca /usr/bin/orca-spire-agent
}

# delete_regular_workloads removes all the non-xname specific workloads from spire
delete_regular_workloads() {
	for computeWorkload in $(kubectl exec -itn spire spire-postgres-0 --container postgres -- su postgres -c "psql spire -c \"SELECT spiffe_id FROM registered_entries where spiffe_id LIKE '%compute/workload%'\" -P "tuples_only" -P "pager 0"" | tr -d "\015" | sort -u); do
		delete_workload_entry "$computeWorkload"
	done

	for ncnWorkload in $(kubectl exec -itn spire spire-postgres-0 --container postgres -- su postgres -c "psql spire -c \"SELECT spiffe_id FROM registered_entries where spiffe_id LIKE '%ncn/workload%'\" -P "tuples_only" -P "pager 0"" | tr -d "\015" | sort -u); do
		delete_workload_entry "$ncnWorkload"
	done

	for storageWorkload in $(kubectl exec -itn spire spire-postgres-0 --container postgres -- su postgres -c "psql spire -c \"SELECT spiffe_id FROM registered_entries where spiffe_id LIKE '%storage/workload%'\" -P "tuples_only" -P "pager 0"" | tr -d "\015" | sort -u); do
		delete_workload_entry "$storageWorkload"
	done

	for uanWorkload in $(kubectl exec -itn spire spire-postgres-0 --container postgres -- su postgres -c "psql spire -c \"SELECT spiffe_id FROM registered_entries where spiffe_id LIKE '%uan/workload%'\" -P "tuples_only" -P "pager 0"" | tr -d "\015" | sort -u); do
		delete_workload_entry "$uanWorkload"
	done
}

# delete_xname_workloads removes all the xname specific workloads from spire
delete_xname_workloads() {
	for computeWorkload in $(kubectl exec -itn spire spire-postgres-0 --container postgres -- su postgres -c "psql spire -c \"SELECT spiffe_id FROM registered_entries where spiffe_id LIKE '%compute/x%/workload%'\" -P \"tuples_only\" -P "pager 0"" | tr -d "\015" | sort -u); do
		delete_workload_entry "$computeWorkload"
	done

	for ncnWorkload in $(kubectl exec -itn spire spire-postgres-0 --container postgres -- su postgres -c "psql spire -c \"SELECT spiffe_id FROM registered_entries where spiffe_id LIKE '%ncn/x%/workload%'\" -P \"tuples_only\" -P "pager 0"" | tr -d "\015" | sort -u); do
		delete_workload_entry "$ncnWorkload"
	done

	for storageWorkload in $(kubectl exec -itn spire spire-postgres-0 --container postgres -- su postgres -c "psql spire -c \"SELECT spiffe_id FROM registered_entries where spiffe_id LIKE '%storage/x%/workload%'\" -P \"tuples_only\" -P "pager 0"" | tr -d "\015" | sort -u); do
		delete_workload_entry "$storageWorkload"
	done

	for uanWorkload in $(kubectl exec -itn spire spire-postgres-0 --container postgres -- su postgres -c "psql spire -c \"SELECT spiffe_id FROM registered_entries where spiffe_id LIKE '%uan/x%/workload%'\" -P \"tuples_only\" -P "pager 0"" | tr -d "\015" | sort -u); do
		delete_workload_entry "$uanWorkload"
	done
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
	kubectl get secrets -n loftsman site-init -o json \
		| jq ".data.\"customizations.yaml\" |= \"$CUSTOMIZATIONS\"" | kubectl apply -f -
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
	RETRY_SECONDS=10
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

enable_xnameValidation() {
	validate_prereqs
	echo "Adding Workload Entries"
	add_xname_workloads
	echo "Enabling xname validation in cray-opa and spire charts"
	backup_customizations
	get_customizations
	enable_xname_in_charts
	create_manifest
	run_loftsman
	update_customizations
	wait_for_spire
	echo "Removing old Workload Entries"
	delete_regular_workloads
}

disable_xnameValidation() {
	validate_prereqs
	echo "Adding non-xname specific Workload Entries"
	add_regular_workloads
	echo "Disabling xname validation in cray-opa and spire charts"
	backup_customizations
	get_customizations
	disable_xname_in_charts
	create_manifest
	run_loftsman
	update_customizations
	wait_for_spire
	echo "Removing xname Workload Entries"
	delete_xname_workloads
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
