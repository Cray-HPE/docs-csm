#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

# shellcheck disable=SC2086

set -e

upgrade_ncn=$1

# shellcheck disable=SC1090,SC2086
. ${BASEDIR}/ncn-upgrade-common.sh $upgrade_ncn

URL="https://api-gw-service-nmn.local/apis/sls/v1/networks"

function on_error() {
    echo "Error: $1.  Exiting"
    exit 1
}

if ! command -v csi &> /dev/null
then
    echo "csi could not be found in $PATH"
    exit 1
fi

# Generate mountain/hill routes for NCNs and add to write_files
function update_write_files_user_data() {
    # Collect network information from SLS
    nmn_hmn_networks=$(curl -k -H "Authorization: Bearer ${TOKEN}" ${URL} 2>/dev/null | jq ".[] | {NetworkName: .Name, Subnets: .ExtraProperties.Subnets[]} | { NetworkName: .NetworkName, SubnetName: .Subnets.Name, SubnetCIDR: .Subnets.CIDR, Gateway: .Subnets.Gateway} | select(.SubnetName==\"network_hardware\") ")
    [[ -n ${nmn_hmn_networks} ]] || on_error "Cannot retrieve HMN and NMN networks from SLS. Check SLS connectivity."
    cabinet_networks=$(curl -k -H "Authorization: Bearer ${TOKEN}" ${URL} 2>/dev/null | jq ".[] | {NetworkName: .Name, Subnets: .ExtraProperties.Subnets[]} | { NetworkName: .NetworkName, SubnetName: .Subnets.Name, SubnetCIDR: .Subnets.CIDR} | select(.SubnetName | startswith(\"cabinet_\")) ")
    [[ -n ${cabinet_networks} ]] || on_error "Cannot retrieve cabinet networks from SLS. Check SLS connectivity."

    # NMN
    nmn_gateway=$(echo "${nmn_hmn_networks}" | jq -r ". | select(.NetworkName==\"NMN\") | .Gateway")
    [[ -n ${nmn_gateway} ]] || on_error "NMN gateway not found"
    nmn_cabinet_subnets=$(echo "${cabinet_networks}" | jq -r ". | select(.NetworkName==\"NMN\" or .NetworkName==\"NMN_RVR\" or .NetworkName==\"NMN_MTN\") | .SubnetCIDR")
    [[ -n ${nmn_cabinet_subnets} ]] || on_error "NMN cabinet subnets not found"

    # HMN
    hmn_gateway=$(echo "${nmn_hmn_networks}" | jq -r ". | select(.NetworkName==\"HMN\") | .Gateway")
    [[ -n ${hmn_gateway} ]] || on_error "HMN gateway not found"
    hmn_cabinet_subnets=$(echo "${cabinet_networks}" | jq -r ". | select(.NetworkName==\"HMN\" or .NetworkName==\"HMN_RVR\" or .NetworkName==\"HMN_MTN\") | .SubnetCIDR")
    [[ -n ${hmn_cabinet_subnets} ]] || on_error "HMN cabinet subnets not found"


    # Format for ifroute-<interface> syntax
    nmn_routes=()
    for rt in $nmn_cabinet_subnets; do
        nmn_routes+=("$rt $nmn_gateway - vlan002")
    done

    hmn_routes=()
    for rt in $hmn_cabinet_subnets; do
        hmn_routes+=("$rt $hmn_gateway - vlan004")
    done

    printf -v nmn_routes_string '%s\\n' "${nmn_routes[@]}"
    printf -v hmn_routes_string '%s\\n' "${hmn_routes[@]}"

    # generate json file for input to csi
cat <<EOF>write-files-user-data.json
{
  "user-data": {
    "write_files": [{
        "content": "${nmn_routes_string%,}",
        "owner": "root:root",
        "path": "/etc/sysconfig/network/ifroute-vlan002",
        "permissions": "0644"
      },
      {
        "content": "${hmn_routes_string%,}",
        "owner": "root:root",
        "path": "/etc/sysconfig/network/ifroute-vlan004",
        "permissions": "0644"
      }
    ]
  }
}
EOF
    # update bss
    csi handoff bss-update-cloud-init --user-data=write-files-user-data.json --limit=${UPGRADE_XNAME}
    ./create-bss-etcd-backup.sh $upgrade_ncn
}

function update_k8s_runcmd_user_data() {
cat <<EOF>k8s-runcmd-user-data.json
{
  "user-data": {
      "runcmd": [
          "/srv/cray/scripts/metal/install-bootloader.sh",
          "/srv/cray/scripts/metal/set-host-records.sh",
          "/srv/cray/scripts/metal/set-dhcp-to-static.sh",
          "/srv/cray/scripts/metal/set-dns-config.sh",
          "/srv/cray/scripts/metal/set-ntp-config.sh",
          "/srv/cray/scripts/metal/enable-lldp.sh",
          "/srv/cray/scripts/metal/set-bmc-bbs.sh",
          "/srv/cray/scripts/metal/set-efi-bbs.sh",
          "/srv/cray/scripts/metal/disable-cloud-init.sh",
          "/srv/cray/scripts/common/update_ca_certs.py",
          "/srv/cray/scripts/metal/install-rpms.sh",
          "/srv/cray/scripts/common/kubernetes-cloudinit.sh"
      ]
  }
}
EOF
    # update bss
    csi handoff bss-update-cloud-init --user-data=k8s-runcmd-user-data.json --limit=${UPGRADE_XNAME}
    ./create-bss-etcd-backup.sh $upgrade_ncn
}

function update_first_ceph_runcmd_user_data() {
cat <<EOF>first-ceph-runcmd-user-data.json
{
  "user-data": {
      "runcmd": [
          "/srv/cray/scripts/metal/install-bootloader.sh",
          "/srv/cray/scripts/metal/set-host-records.sh",
          "/srv/cray/scripts/metal/set-dhcp-to-static.sh",
          "/srv/cray/scripts/metal/set-dns-config.sh",
          "/srv/cray/scripts/metal/set-ntp-config.sh",
          "/srv/cray/scripts/metal/enable-lldp.sh",
          "/srv/cray/scripts/metal/set-bmc-bbs.sh",
          "/srv/cray/scripts/metal/set-efi-bbs.sh",
          "/srv/cray/scripts/metal/disable-cloud-init.sh",
          "/srv/cray/scripts/common/update_ca_certs.py",
          "/srv/cray/scripts/metal/install-rpms.sh",
          "/srv/cray/scripts/common/pre-load-images.sh",
          "/srv/cray/scripts/common/storage-ceph-cloudinit.sh"
      ]
  }
}
EOF
    # update bss
    csi handoff bss-update-cloud-init --user-data=first-ceph-runcmd-user-data.json --limit=${UPGRADE_XNAME}
    ./create-bss-etcd-backup.sh $upgrade_ncn
}

function update_ceph_worker_runcmd_user_data() {
cat <<EOF>ceph-worker-runcmd-user-data.json
{
  "user-data": {
      "runcmd": [
          "/srv/cray/scripts/metal/install-bootloader.sh",
          "/srv/cray/scripts/metal/set-host-records.sh",
          "/srv/cray/scripts/metal/set-dhcp-to-static.sh",
          "/srv/cray/scripts/metal/set-dns-config.sh",
          "/srv/cray/scripts/metal/set-ntp-config.sh",
          "/srv/cray/scripts/metal/enable-lldp.sh",
          "/srv/cray/scripts/metal/set-bmc-bbs.sh",
          "/srv/cray/scripts/metal/set-efi-bbs.sh",
          "/srv/cray/scripts/metal/disable-cloud-init.sh",
          "/srv/cray/scripts/common/update_ca_certs.py",
          "/srv/cray/scripts/metal/install-rpms.sh",
          "/srv/cray/scripts/common/pre-load-images.sh"
      ]
  }
}
EOF
    # update bss
    csi handoff bss-update-cloud-init --user-data=ceph-worker-runcmd-user-data.json --limit=${UPGRADE_XNAME}
    ./create-bss-etcd-backup.sh $upgrade_ncn
}

# same data on all NCNs
update_write_files_user_data

case ${upgrade_ncn} in
    ncn-s001)
        update_first_ceph_runcmd_user_data
        ;;
    ncn-s*)
        update_ceph_worker_runcmd_user_data
        ;;
    *)
        update_k8s_runcmd_user_data
        ;;
esac
