#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

# shellcheck disable=SC2086

set -e

upgrade_ncn=$1

# shellcheck disable=SC1090,SC2086
. ${BASEDIR}/ncn-upgrade-common.sh $upgrade_ncn

URL="https://api-gw-service-nmn.local/apis/sls/v1/networks"

function on_error() {
    echo "Error: $1. Exiting"
    exit 1
}

if ! command -v csi &> /dev/null
then
    echo "csi could not be found in $PATH"
    exit 1
fi

# # sem_version() converts a semver string so it can be compared in a test statement
# function sem_version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }
#
# # Get the current csi version
# csi_version=$(csi version | awk '/App\. Version/ {print $4}')
#
# # v1.5.32 is when the new NTP metadata was installed, so check it is older than that
# if [ "$(sem_version $csi_version)" -le "$(sem_version "1.6.32")" ]; then
#     echo "Update csi to at least v1.5.32"
#     exit 2
# fi

# upgrade_ntp_timezone_metadata() will query a data.json to pull out the new ntp keys and then push them back into bss
upgrade_ntp_timezone_metadata() {
  local ntp_query
  local ntp_payload
  local timezone_query
  local timezone_payload
  local upgrade_file
  # jq -r '.["b8:59:9f:fe:49:f1"]["user-data"]["ntp"]' ntp.json
  for k in $(jq -r 'to_entries[] | "\(.key)"' data.json)
  do
    # if it is not the global key, it is one of the host records we need to manipulate
    if ! [[ "$k" == "Global" ]]; then
      # shellcheck disable=SC2089
      ntp_query=".[\"$k\"][\"user-data\"][\"ntp\"]"
      # shellcheck disable=SC2090
      ntp_payload="$(jq $ntp_query data.json)"

      # shellcheck disable=SC2089
      timezone_query=".[\"$k\"][\"user-data\"][\"timezone\"]"
      # shellcheck disable=SC2090
      timezone_payload="$(jq $timezone_query data.json)"

      # save the payload to a unique file
      upgrade_file="upgrade-metadata-${k//:}.json"
      cat <<EOF>"$upgrade_file"
{
  "user-data": {
    "ntp": $ntp_payload,
    "timezone": $timezone_payload
  }
}
EOF
      # handoff the new payload to bss
      csi handoff bss-update-cloud-init --user-data="$upgrade_file" --limit=${UPGRADE_XNAME}
    fi
  done
  # jq -r 'keys[] as $k | "\($k), \(.[$k] | .["user-data"]["ntp"])"' data.json
}

# patch_in_new_metadata() will mount PITDATA and run 'csi config init' in order to grab the newly-generated data.json and then push it into bss
patch_in_new_metadata() {
  # mount the partition that should have the files we need
  mkdir -p /mnt/pitdata

  prep_dir=/mnt/pitdata/prep
  # find the three seed files
  ncn_metadata="$prep_dir"/ncn_metadata.csv
  switch_metadata="$prep_dir"/switch_metadata.csv
  hmn_connections="$prep_dir"/hmn_connections.json
  system_config="$prep_dir"/system_config.yaml

  if ! eval blkid -t LABEL=PITDATA >/dev/null; then
    if [[ -f "$ncn_metadata" ]] \
      && [[ -f "$switch_metadata" ]] \
      && [[ -f "$hmn_connections" ]] \
      && [[ -f "$system_config" ]]; then
        echo "PITDATA not found but seed files are present. Using those to generate new metadata..."
    else
      echo "PITDATA not found. Seed files needed to generate new cloud-init metadata."
      echo "Re-create/re-populate the PITDATA partition"
      echo "or"
      echo "Copy seed files to /mnt/pitdata/prep"
      exit 1
    fi
  else
    echo "Mounting PITDATA..."
      if ! eval mount | grep '\/mnt\/pitdata' >/dev/null; then
        mount -L PITDATA /mnt/pitdata/
      fi
  fi


  # we need the three seed files and the system_config to generate the metadata
  # this also ensures we are in the right place to run config init without any arguments
  if [[ -f "$ncn_metadata" ]] \
      && [[ -f "$switch_metadata" ]] \
      && [[ -f "$hmn_connections" ]] \
      && [[ -f "$system_config" ]]; then
        # find the system name
        system_name=$(awk '/system-name/ {print $2}' "$system_config")
        if ! [[ -d "$prep_dir/$system_name-0.9" ]]; then
          pushd "$prep_dir" || exit 1
            # move the original generated configs out of the way
            mv "$system_name" "$system_name-0.9"
            echo "Generating new config payload for $system_name with csi..."
            # Run config init to get the new metadata
            csi config init
            echo "Getting new ntp metadata..."
            # handoff the new data to bss
            pushd "$system_name/basecamp" || exit 1
              upgrade_ntp_timezone_metadata
            popd || exit 1
          popd || exit 1
        fi
  else
    echo "Missing seed file or system_config.yaml"
    exit 1
  fi

  if eval mount | grep '\/mnt\/pitdata' >/dev/null; then
    umount -l /mnt/pitdata/ || true
  fi
}

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
        nmn_routes+=("$rt $nmn_gateway - bond0.nmn0")
    done

    hmn_routes=()
    for rt in $hmn_cabinet_subnets; do
        hmn_routes+=("$rt $hmn_gateway - bond0.hmn0")
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
        "path": "/etc/sysconfig/network/ifroute-bond0.nmn0",
        "permissions": "0644"
      },
      {
        "content": "${hmn_routes_string%,}",
        "owner": "root:root",
        "path": "/etc/sysconfig/network/ifroute-bond0.hmn0",
        "permissions": "0644"
      }
    ]
  }
}
EOF
    # update bss
    csi handoff bss-update-cloud-init --user-data=write-files-user-data.json --limit=${UPGRADE_XNAME}
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
}

# same data on all NCNs
update_write_files_user_data
patch_in_new_metadata

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
