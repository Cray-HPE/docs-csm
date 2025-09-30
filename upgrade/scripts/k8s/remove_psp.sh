#!/bin/bash

# Overview of the resources for implementing PSP
#
# <pod> contains reference to:
#     <serviceaccount>
# <role> or <clusterrole> contains reference to
#     <PSP>
# <rolebinding> or <clusterrolebinding> link
#     <serviceaccount>
# and
#     <clusterrole>
#
# <pod> ==> <serviceaccount> <-- <clusterrolebinding> ==> <clusterrole> ==> <PSP>

# Check for PSP
#   On each master node, edit
#     /etc/kubernetes/manifests/kube-apiserver.yaml
#   and remove the line with:
#     enable-admission-plugins=PodSecurityPolicy
#
# sed -i '/enable-admission-plugins=PodSecurityPolicy/d' /etc/kubernetes/manifests/kube-apiserver.yaml"
#
# The kubelet will automatically restart the kube-apiserver pods.  Wait for each kube-apiserver
# pod to restart and enter Running state before restarting the next one

# DRY_RUN=--dry-run=server
DRY_RUN=""

apiserver_has_psp()
{
    echo "Checking if PSP has been disabled on all control plane nodes"
    ret_val=1
    api_servers=$(kubectl get pods -n kube-system -lcomponent=kube-apiserver -ojsonpath='{.items[*].metadata.name}')
    for server in ${api_servers}; do
        if kubectl get pod -n kube-system "${server}" -o yaml | grep -q "enable-admission-plugins=.*PodSecurityPolicy"; then
           ret_val=0
           echo "${server} has the PodSecurityPolicy plugin  enabled.  Please disable it by running:"
           echo "    sed -i 's/,*PodSecurityPolicy//' /etc/kubernetes/manifests/kube-apiserver.yaml"
           echo "    sed -i '/enable-admission-plugins=$/d' /etc/kubernetes/manifests/kube-apiserver.yaml"
           echo "on ${server#kube-apiserver-}"
           echo "The kubelet will detect the change and automatically restart ${server}"
           echo
        fi
    done
    return "${ret_val}"
}


# A list of known PSPs, taking from system running CSM 1.6
DEFAULT_PSPS="cray-ceph-csi-cephfs-nodeplugin cray-ceph-csi-cephfs-provisioner"
DEFAULT_PSPS="${DEFAULT_PSPS} cray-ceph-csi-rbd-nodeplugin cray-ceph-csi-rbd-provisioner"
DEFAULT_PSPS="${DEFAULT_PSPS} cray-certmanager-cert-manager cray-certmanager-cert-manager-cainjector"
DEFAULT_PSPS="${DEFAULT_PSPS} cray-certmanager-cert-manager-webhook cray-externaldns-external-dns-services"
DEFAULT_PSPS="${DEFAULT_PSPS} cray-kyverno-admission-controller cray-kyverno-background-controller"
DEFAULT_PSPS="${DEFAULT_PSPS} cray-kyverno-cleanup-admission-reports"
DEFAULT_PSPS="${DEFAULT_PSPS} cray-kyverno-cleanup-cluster-admission-reports cray-kyverno-cleanup-controller"
DEFAULT_PSPS="${DEFAULT_PSPS} cray-kyverno-post-install-job cray-kyverno-psp cray-kyverno-reports-controller"
DEFAULT_PSPS="${DEFAULT_PSPS} cray-spire cray-spire-agent cray-sysmgmt-health-grafana"
DEFAULT_PSPS="${DEFAULT_PSPS} cray-sysmgmt-health-kube-state-metrics cray-sysmgmt-health-prometheus-node-exporter"
DEFAULT_PSPS="${DEFAULT_PSPS} metallb-controller metallb-speaker node-problem-detector"
DEFAULT_PSPS="${DEFAULT_PSPS} privileged restricted restricted-transition restricted-transition-net-raw"
DEFAULT_PSPS="${DEFAULT_PSPS} sealed-secrets-kube-system sma-vm-cluster spire spire-agent uas-default-psp"

delete_any_psp()
{
    PSPS=$(kubectl get psp -ojsonpath='{.items[*].metadata.name}' 2>/dev/null)
    if [ -z "${PSPS}" ]; then
        echo "No existing podsecuritypolices"
        PSPS="${DEFAULT_PSPS}"
        return 0
    fi
    PSPS=$(echo ${DEFAULT_PSPS} ${PSPS} | tr ' ' '\n' | sort -u | tr '\n' ' ')
    echo "Deleting all podsecuritypolicies"
    kubectl delete ${DRY_RUN} psp --all
    return 0
}

# A list of known Cluster Roles that point to PSPs, taken from system running CSM 1.6
KNOWN_PSP_CR="cray-certmanager-cert-manager-cainjector-psp cray-certmanager-cert-manager-psp"
KNOWN_PSP_CR="${KNOWN_PSP_CR} cray-certmanager-cert-manager-webhook-psp cray-externaldns-external-dns-services-psp"
KNOWN_PSP_CR="${KNOWN_PSP_CR} cray-kyverno-admission-controller cray-kyverno-background-controller"
KNOWN_PSP_CR="${KNOWN_PSP_CR} cray-kyverno-cleanup-admission-reports cray-kyverno-cleanup-cluster-admission-reports"
KNOWN_PSP_CR="${KNOWN_PSP_CR} cray-kyverno-cleanup-controller cray-kyverno-psp cray-kyverno-reports-controller"
KNOWN_PSP_CR="${KNOWN_PSP_CR} cray-spire cray-spire-agent-psp node-problem-detector-psp privileged-psp"
KNOWN_PSP_CR="${KNOWN_PSP_CR} psp-cray-sysmgmt-health-kube-state-metrics psp-cray-sysmgmt-health-prometheus-node-exporter"
KNOWN_PSP_CR="${KNOWN_PSP_CR} restricted-psp restricted-transition-net-raw-psp restricted-transition-psp"
KNOWN_PSP_CR="${KNOWN_PSP_CR} sealed-secrets-kube-system-psp sma-vm-cluster-clusterrole spire spire-agent-psp uas-default-psp"

# Get 3 list of clusterroles:
#     CLUSTERROLE_NO_PSP: ClusterRoles that do not have PSP resources
#     CLUSTERROLE_ONLY_PSP: ClusterRoles that have only PSP resources
#     CLUSTERROLE_MIXED_PSP: ClusterRoles that have a mix of PSP and non-PSP resources
get_clusterroles()
{
    CR=$(kubectl get clusterrole -ojsonpath='{.items[*].metadata.name}')
    CLUSTERROLES=$(echo ${CR} ${KNOWN_PSP_CR}| tr ' ' '\n' | sort -u | tr '\n' ' ')

    CLUSTERROLE_NO_PSP=""
    CLUSTERROLE_ONLY_PSP=""
    CLUSTERROLE_MIXED_PSP=""
    CLUSTERROLE_NX=""
    for cr in ${CLUSTERROLES}; do
        if ! resources=$(kubectl get clusterrole "${cr}" -o jsonpath='{.rules[*].resources[*]}{"\n"}' 2>/dev/null); then
            CLUSTERROLE_NX="${CLUSTERROLE_NX} ${cr}"
        elif [ "${resources}" = podsecuritypolicies ]; then
            CLUSTERROLE_ONLY_PSP="${CLUSTERROLE_ONLY_PSP} ${cr}"
        elif echo "${resources}" | grep -q podsecuritypolicies; then
            CLUSTERROLE_MIXED_PSP="${CLUSTERROLE_MIXED_PSP} ${cr}"
        else
            CLUSTERROLE_NO_PSP="${CLUSTERROLE_NO_PSP} ${cr}"
        fi
    done
    echo "CLUSTERROLE_NX: ${CLUSTERROLE_NX}"
    echo "CLUSTERROLE_ONLY_PSP: ${CLUSTERROLE_ONLY_PSP}"
    echo "CLUSTERROLE_MIXED_PSP: ${CLUSTERROLE_MIXED_PSP}"
}

# Delete a list of clusterroles, specified as a list of:
#     <clusterrole>
delete_clusterroles()
{
    if [ -n "$*" ]; then
        kubectl delete ${DRY_RUN} clusterrole "$@"
    fi
}

# For clusterroles that have multiple resources, delete just the
# "podsecuritypolicies" element from the array of resources
# in the role.  The roles are specified as a list of:
#     <clusterrole>
delete_psp_from_clusterroles()
{
    for cr in "$@"; do
        #kubectl get clusterrole "${cr}" -o json | jq 'del(.rules[] | select(.resources[0]=="podsecuritypolicies"))' | kubectl apply ${DRY_RUN} -f -

        INDEX=$(kubectl get clusterrole "${cr}" -o json  | jq '.rules | map(.resources[0] == "podsecuritypolicies") | index(true)')
        kubectl patch ${DRY_RUN} clusterrole "${cr}" --type=json -p="[{'op': 'remove', 'path': '/rules/${INDEX}'}]"
    done
}


KNOWN_PSP_R="ceph-cephfs/cray-ceph-csi-cephfs-nodeplugin ceph-rbd/cray-ceph-csi-rbd-nodeplugin sma/sma-vm-cluster sysmgmt-health/cray-sysmgmt-health-grafana"

# Get 3 list of roles:
#     ROLE_NO_PSP: ClusterRoles that do not have PSP resources
#     ROLE_ONLY_PSP: ClusterRoles that have only PSP resources
#     ROLE_MIXED_PSP: ClusterRoles that have a mix of PSP and non-PSP resources
get_roles()
{
    # Get a list of Roles
    R=$(kubectl get roles -A -ojsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}')
    ROLES=$(echo ${R} ${KNOWN_PSP_R}| tr ' ' '\n' | sort -u | tr '\n' ' ')

    ROLE_NO_PSP=""
    ROLE_ONLY_PSP=""
    ROLE_MIXED_PSP=""
    for nr in ${ROLES}; do
        ns=${nr%/*}
        r=${nr#*/}
        if ! resources=$(kubectl get role -n "${ns}" "${r}" -o jsonpath='{.rules[*].resources[*]}{"\n"}' 2>/dev/null); then
            ROLE_NX="${ROLE_NX} ${nr}"
        elif [ "${resources}" = podsecuritypolicies ]; then
            ROLE_ONLY_PSP="${ROLE_ONLY_PSP} ${nr}"
        elif echo "${resources}" | grep -q podsecuritypolicies; then
            ROLE_MIXED_PSP="${ROLE_MIXED_PSP} ${nr}"
        else
            ROLE_NO_PSP="${ROLE_NO_PSP} ${nr}"
        fi
    done
    echo "ROLE_NX: ${ROLE_NX}"
    echo "ROLE_ONLY_PSP: ${ROLE_ONLY_PSP}"
    echo "ROLE_MIXED_PSP: ${ROLE_MIXED_PSP}"
}

# Delete a list of roles, specified as a list of:
#     <namespace>/<role>
delete_roles()
{
    for nr in "$@"; do
        ns=${nr%/*}
        r=${nr#*/}
        kubectl delete ${DRY_RUN} role -n "${ns}" "${r}"
    done
}

# For roles that have multiple resources, delete just the
# "podsecuritypolicies" element from the array of resources
# in the role.  The roles are specified as a list of:
#     <namespace>/<role>
delete_psp_from_roles()
{
    for nr in "$@"; do
        ns=${nr%/*}
        r=${nr#*/}
        INDEX=$(kubectl get role -n "${ns}" "${r}" -o json  | jq '.rules | map(.resources[0] == "podsecuritypolicies") | index(true)')
        kubectl patch ${DRY_RUN} role -n "${ns}" "${r}" --type=json -p="[{'op': 'remove', 'path': '/rules/${INDEX}'}]"
    done
}

# Get 3 list of clusterrolebindings:
#     CLUSTERROLEBINDING_NO_SA: ClusterRoleBindings that do not have SA kinds
#     CLUSTERROLEBINDING_ONLY_SA: ClusterRoleBindings that have only SA kinds
#     CLUSTERROLEBINDING_MIXED_SA: ClusterRoleBindings that have a mix of SA and non-SA kinds
get_clusterrolebindings()
{
    CLUSTERROLEBINDINGS=$(kubectl get clusterrolebinding -ojsonpath='{.items[*].metadata.name}')

    CLUSTERROLEBINDING_NO_PSP=""
    CLUSTERROLEBINDING_ONLY_PSP=""
    CLUSTERROLEBINDING_MIXED_PSP=""
    for cr in ${CLUSTERROLEBINDINGS}; do
        kind_name_subj=$(kubectl get clusterrolebinding "${cr}" -o jsonpath='{.roleRef.kind}/{.roleRef.name}@{range .subjects[*]}{.kind}/{.name}/{.namespace}{" "}{end}{"\n"}')
        kind_name=${kind_name_subj%@*}
        kind=${kind_name%/*}
        name=${kind_name#*/}
        if [ "${kind}" = ClusterRole ]; then
           if echo " ${CLUSTERROLE_NX} ${CLUSTERROLE_ONLY_PSP} " | grep -q " ${name} "; then
               CLUSTERROLEBINDING_ONLY_PSP="${CLUSTERROLEBINDING_ONLY_PSP} ${cr}"
               PSP_ONLY_SA="${PSP_ONLY_SA}${kind_name_subj#*@}"
           elif echo " ${CLUSTERROLE_MIXED_PSP} " | grep -q " ${name} "; then
               CLUSTERROLEBINDING_MIXED_PSP="${CLUSTERROLEBINDING_MIXED_PSP} ${cr}"
           else
               CLUSTERROLEBINDING_NO_PSP="${CLUSTERROLEBINDING_NO_PSP} ${cr}"
           fi
        else
           CLUSTERROLEBINDING_OTHER="${CLUSTERROLEBINDING_OTHER} ${cr}/${kind}/${name}"
        fi
    done
    echo "CLUSTERROLEBINDING_ONLY_PSP: ${CLUSTERROLEBINDING_ONLY_PSP}"
    echo "CLUSTERROLEBINDING_MIXED_PSP: ${CLUSTERROLEBINDING_MIXED_PSP}"
    echo "CLUSTERROLEBINDING_OTHER: ${CLUSTERROLEBINDING_OTHER}"
}

# Delete a list of clusterrolebindings, specified as a list of:
#     <clusterrolebinding>
delete_clusterrolebindings()
{
    kubectl delete ${DRY_RUN} clusterrolebindings "$@"
}

# Get 3 list of rolesbindings:
#     ROLEBINDING_NO_SA: RoleBindings that do not have SA kinds
#     ROLEBINDING_ONLY_SA: RoleBindings that have only SA kinds
#     ROLEBINDING_MIXED_SA: RoleBindings that have a mix of SA and non-SA kinds
get_rolebindings()
{
    # Get a list of Roles
    ROLEBINDINGS=$(kubectl get rolebindings -A -ojsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}')

    ROLEBINDING_CLUSTER_ONLY_PSP=""
    ROLEBINDING_CLUSTER_MIXED_PSP=""
    ROLEBINDING_CLUSTER_NO_PSP=""
    ROLEBINDING_ONLY_PSP=""
    ROLEBINDING_MIXED_PSP=""
    ROLEBINDING_NO_PSP=""
    ROLEBINDING_OTHER=""
    for nr in ${ROLEBINDINGS}; do
        ns=${nr%/*}
        r=${nr#*/}

        kind_name_subj=$(kubectl get rolebinding -n "${ns}" "${r}" -o jsonpath='{.roleRef.kind}/{.roleRef.name}@{range .subjects[*]}{.kind}/{.name}/{.namespace}{":'"${ns}"' "}{end}{"\n"}')
        kind_name=${kind_name_subj%@*}
        kind=${kind_name%/*}
        name=${kind_name#*/}
        if [ "${kind}" = ClusterRole ]; then
           if echo "  ${CLUSTERROLE_NX} ${CLUSTERROLE_ONLY_PSP} " | grep -q " ${name} "; then
               ROLEBINDING_CLUSTER_ONLY_PSP="${ROLEBINDING_CLUSTER_ONLY_PSP} ${nr}"
               PSP_ONLY_SA="${PSP_ONLY_SA}${kind_name_subj#*@}"
           elif echo " ${CLUSTERROLE_MIXED_PSP} " | grep -q " ${name} "; then
               ROLEBINDING_CLUSTER_MIXED_PSP="${ROLEBINDING_CLUSTER_MIXED_PSP} ${nr}"
           else
               ROLEBINDING_CLUSTER_NO_PSP="${ROLEBINDING_CLUSTER_NO_PSP} ${nr}"
           fi
        elif [ "${kind}" = Role ]; then
           if echo " ${ROLE_NX} ${ROLE_ONLY_PSP} " | grep -q " ${name} "; then
               ROLEBINDING_ONLY_PSP="${ROLEBINDING_ONLY_PSP} ${nr}"
               PSP_ONLY_SA="${PSP_ONLY_SA}${kind_name_subj#*@}"
           elif echo " ${ROLE_MIXED_PSP} " | grep -q " ${name} "; then
               ROLEBINDING_MIXED_PSP="${ROLEBINDING_MIXED_PSP} ${nr}"
           else
               ROLEBINDING_NO_PSP="${ROLEBINDING_NO_PSP} ${nr}"
           fi
        else
           ROLEBINDING_OTHER="${ROLEBINDING_OTHER} ${nr}/${kind}/${name}"
        fi
    done
    echo "ROLEBINDING_CLUSTER_ONLY_PSP: ${ROLEBINDING_CLUSTER_ONLY_PSP}"
    echo "ROLEBINDING_CLUSTER_MIXED_PSP: ${ROLEBINDING_CLUSTER_MIXED_PSP}"
    echo "ROLEBINDING_ONLY_PSP: ${ROLEBINDING_ONLY_PSP}"
    echo "ROLEBINDING_MIXED_PSP: ${ROLEBINDING_MIXED_PSP}"
    echo "ROLEBINDING_OTHER: ${ROLEBINDING_OTHER}"
}

# Delete a list of rolebindings, specified as a list of:
#     <namespace>/<rolebinding>
delete_rolebindings()
{
    for nr in "$@"; do
        ns=${nr%/*}
        r=${nr#*/}
        kubectl delete ${DRY_RUN} rolebinding -n "${ns}" "${r}"
    done
}

get_sa()
{
    echo "PSP_ONLY_SA=${PSP_ONLY_SA}"
    echo

    for sa in ${PSP_ONLY_SA}; do
        kind=${sa%%/*}
        if [[ "${kind}" != ServiceAccount ]]; then
            continue
        fi
        name_ns=${sa#*/}
        name=${name_ns%%/*}
        # namespace is
        #     <namespace>[:<namespace>]
        # If the first one is empty, use the second one
        ns_tmp=${name_ns#*/}
        ns=${ns_tmp%:*}
        if [[ -z ${ns} ]]; then
            ns=${ns_tmp#*:}
        fi
        echo "${sa} ==> kind=${kind} name=${name} ns=${ns}"
    done

}

delete_sa()
{
    echo "delete_sa(): NOP"
}


if apiserver_has_psp; then
    echo "Please disable PSP on all control plane nodes before running this script"
    exit 1
fi

delete_any_psp

get_clusterroles

# shellcheck disable=SC2086
delete_clusterroles ${CLUSTERROLE_ONLY_PSP}

# shellcheck disable=SC2086
delete_psp_from_clusterroles ${CLUSTERROLE_MIXED_PSP}

get_roles

# shellcheck disable=SC2086
delete_roles ${ROLE_ONLY_PSP}

# shellcheck disable=SC2086
delete_psp_from_roles ${ROLE_MIXED_PSP}

get_clusterrolebindings

# shellcheck disable=SC2086
delete_clusterrolebindings ${CLUSTERROLEBINDING_ONLY_PSP}

get_rolebindings

# shellcheck disable=SC2086
delete_rolebindings ${ROLEBINDING_CLUSTER_ONLY_PSP} ${ROLEBINDING_ONLY_PSP}

get_sa

delete_sa
