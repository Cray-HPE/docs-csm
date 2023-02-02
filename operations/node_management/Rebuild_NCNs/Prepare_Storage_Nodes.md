# Prepare Storage Nodes

Prepare a storage node before rebuilding it.

**IMPORTANT:** All of the output examples may not reflect the cluster status where this operation is being performed. For example, if this is a rebuild in place, then Ceph components will not be reporting down, in contrast to a failed node rebuild.

## Prerequisites

When rebuilding a node, make sure that the `/srv/cray/scripts/common/storage-ceph-cloudinit.sh` and `/srv/cray/scripts/common/pre-load-images.sh`, has been removed from the `runcmd` in BSS.

1. (`ncn-m001#`) Set node name and xname if not already set.

   ```bash
   NODE=ncn-s00n
   XNAME=$(ssh $NODE cat /etc/cray/xname)
   ```

1. (`ncn-m001#`) Get the `runcmd` in BSS.

   ```bash
   cray bss bootparameters list --name ${XNAME} --format=json|jq -r '.[]|.["cloud-init"]|.["user-data"].runcmd'
   ```

   Expected Output:

   ```json
   [
   "/srv/cray/scripts/metal/net-init.sh",
   "/srv/cray/scripts/common/update_ca_certs.py",
   "/srv/cray/scripts/metal/install.sh",
   "/srv/cray/scripts/common/ceph-enable-services.sh",
   "touch /etc/cloud/cloud-init.disabled"
   ]
   ```

   If `/srv/cray/scripts/common/storage-ceph-cloudinit.sh` or `/srv/cray/scripts/common/pre-load-images.sh` is in the `runcmd`, then it will need to be fixed by running:

   A token will need to be generated and made available as an environment variable. Refer to the [Retrieve an Authentication Token](../../security_and_authentication/Retrieve_an_Authentication_Token.md) procedure for more information.

   **IMPORTANT:** The below python script is provided by the `docs-csm` RPM. To install the latest version of it, see [Check for Latest Documentation](../../../update_product_stream/README.md#check-for-latest-documentation).

   ```bash
   python3 /usr/share/doc/csm/scripts/patch-ceph-runcmd.py
   ```

## Procedure

Upload ceph container images into nexus.

1. (`ncn-s#`) Copy and paste the below script into `/srv/cray/scripts/common/upload_ceph_images_to_nexus.sh` **on the node being rebuilt**.

    ```bash
    #!/bin/bash

    nexus_username=$(ssh ncn-m001 'kubectl get secret -n nexus nexus-admin-credential --template={{.data.username}} | base64 --decode')
    nexus_password=$(ssh ncn-m001 'kubectl get secret -n nexus nexus-admin-credential --template={{.data.password}} | base64 --decode')

    function upload_image_and_upgrade() {
        # get local image and nexus image location
        name=$1
        prefix=$2
        to_configure=$3
        local_image=$(ceph --name client.ro orch ps --format json | jq --arg DAEMON $name '.[] | select(.daemon_type == $DAEMON) | .container_image_name' | tr -d '"' | sort -u | tail -1)
        # if sha in image then remove and use version
        if [[ $local_image == *"@sha"* ]]; then
            without_sha=${local_image%"@sha"*}
            version=$(ceph --name client.ro orch ps --format json | jq --arg DAEMON $name '.[] | select(.daemon_type == $DAEMON) | .version' | tr -d '"' | sort -u)
            if [[ $version != "v"* ]]; then version="v""$version"; fi
            local_image="$without_sha"":""$version"
        fi
        nexus_location="${prefix}""$(echo "$local_image" | rev | cut -d "/" -f1 | rev)"

        # push images to nexus, point to nexus and run upgrade
        echo "Pushing image: $local_image to $nexus_location"
        podman pull $local_image
        podman tag $local_image $nexus_location
        podman push --creds $nexus_username:$nexus_password $nexus_location
        for storage_node in "ncn-s001" "ncn-s002" "ncn-s003"; do
            ssh $storage_node "ceph config set mgr $to_configure $nexus_location"
            if [[ $? == 0 ]]; then
              break
            fi
        done
        
        # run upgrade if mgr
        if [[ $name == "mgr" ]]; then
          for storage_node in "ncn-s001" "ncn-s002" "ncn-s003"; do
            ssh $storage_node "ceph orch upgrade start --image $nexus_location"
            if [[ $? == 0 ]]; then
              break
            fi
          done
        fi
    }

    #prometheus, node-exporter, and alertmanager have this prefix
    prometheus_prefix="registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/prometheus/"
    upload_image_and_upgrade "prometheus" $prometheus_prefix "mgr/cephadm/container_image_prometheus"
    upload_image_and_upgrade "node-exporter" $prometheus_prefix "mgr/cephadm/container_image_node_exporter"
    upload_image_and_upgrade "alertmanager" $prometheus_prefix "mgr/cephadm/container_image_alertmanager"

    # mgr and grafana have this prfix
    ceph_prefix="registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/"
    upload_image_and_upgrade "grafana" $ceph_prefix "mgr/cephadm/container_image_grafana"
    upload_image_and_upgrade "mgr" $ceph_prefix "container_image"

    # watch upgrade status
    echo "Waiting for upgrade to complete..."
    sleep 10
    int=0
    success=false
    while [[ $int -lt 100 ]] && ! $success; do
      for storage_node in "ncn-s001" "ncn-s002" "ncn-s003"; do
        error=$(ssh $storage_node "ceph orch upgrade status --format json | jq '.message' | grep Error")
        if [[ -n $error ]]; then
          echo "Error: there was an issue with the upgrade. Run 'ceph orch upgrade status' from ncn-s00[1/2/3]."
          exit 1
        fi
        if [[ $(ssh $storage_node "ceph orch upgrade status --format json | jq '.in_progress'") != "true" ]]; then
          echo "Upgrade complete"
          success=true
          break
        else
          int=$(( $int + 1 ))
          sleep 10
        fi
      done
    done

    # restart daemons
    for daemon in "prometheus" "node-exporter" "alertmanager" "grafana"; do
      daemons_to_restart=$(ceph --name client.ro orch ps | awk '{print $1}' | grep $daemon)
      for each in $daemons_to_restart; do
        for storage_node in "ncn-s001" "ncn-s002" "ncn-s003"; do
            ssh $storage_node "ceph orch daemon redeploy $each"
            if [[ $? == 0 ]]; then
              break
            fi
          done
      done
    done

    echo "Process is complete."
    ```
1. Change the mode of the script.

    ```bash
    chmod u+x /srv/cray/scripts/common/upload_ceph_images_to_nexus.sh
    ```
1. Execute the script.

    ```bash
    /srv/cray/scripts/common/upload_ceph_images_to_nexus.sh
    ```

1. (`ncn-s00[1/2/3]#`) After running the script, run the following command to check for errors or completion of the `ceph orch upgrade` command run in the script.

    ```bash
    ceph orch upgrade status
    ```

    Expected output:

    ```bash
    {
    "target_image": null,
    "in_progress": false,
    "services_complete": [],
    "progress": null,
    "message": ""
    }
    ```

Check the status of Ceph.

1. If the node is up, then stop and disable all the Ceph services on the node being rebuilt.

    (`ncn-s#`) On the node being rebuilt, run:

    ```bash
    for service in $(cephadm ls |jq -r '.[].systemd_unit'); do systemctl stop $service; systemctl disable $service; done
    ```

    Example output:

    ```screen
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.39.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@mgr.ncn-s003.tjuyhj.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@mon.ncn-s003.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.41.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.36.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.37.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@mds.cephfs.ncn-s003.jcnovs.    service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.40.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@crash.ncn-s003.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@node-exporter.ncn-s003.service.
    Removed /etc/systemd/system/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14.target.    wants/ceph-184b8c56-172d-11ec-aa96-a4bf0138ee14@osd.38.service.
    ```

1. Check the OSD status, weight, and location:

    ```bash
    ceph osd tree
    ```

    Example output:

    ```text
    ID CLASS WEIGHT   TYPE NAME         STATUS REWEIGHT PRI-AFF
    -1       20.95917 root default
    -3        6.98639     host ncn-s001
     2   ssd  1.74660         osd.2         up  1.00000 1.00000
     5   ssd  1.74660         osd.5         up  1.00000 1.00000
     8   ssd  1.74660         osd.8         up  1.00000 1.00000
    11   ssd  1.74660         osd.11        up  1.00000 1.00000
    -7        6.98639     host ncn-s002
     0   ssd  1.74660         osd.0         up  1.00000 1.00000
     4   ssd  1.74660         osd.4         up  1.00000 1.00000
     7   ssd  1.74660         osd.7         up  1.00000 1.00000
    10   ssd  1.74660         osd.10        up  1.00000 1.00000
    -5        6.98639     host ncn-s003
     1   ssd  1.74660         osd.1       down        0 1.00000
     3   ssd  1.74660         osd.3       down        0 1.00000
     6   ssd  1.74660         osd.6       down        0 1.00000
     9   ssd  1.74660         osd.9       down        0 1.00000
    ```

1. Check the status of the Ceph cluster:

    ```screen
    ceph -s
    ```

    Example output:

    ```text
      cluster:
        id:     184b8c56-172d-11ec-aa96-a4bf0138ee14
        health: HEALTH_WARN
                1/3 mons down, quorum ncn-s001,ncn-s002
                6 osds down
                1 host (6 osds) down
                Degraded data redundancy: 21624/131171 objects degraded (16.485%),     522 pgs degraded, 763 pgs undersized

      services:
        mon: 3 daemons, quorum ncn-s001,ncn-s002 (age 3m), out of quorum: ncn-s003
        mgr: ncn-s001.afiqwl(active, since 14h), standbys: ncn-s002.nafbdr
        mds: cephfs:1 {0=cephfs.ncn-s001.nzsgxr=up:active} 1 up:standby-replay
        osd: 36 osds: 30 up (since 3m), 36 in (since 14h)
        rgw: 3 daemons active (site1.zone1.ncn-s002.tipbuf, site1.zone1.ncn-s004.    uvzcms, site1.zone1.ncn-s005.twisxx)

      task status:

      data:
        pools:   12 pools, 1641 pgs
        objects: 43.72k objects, 81 GiB
        usage:   228 GiB used, 63 TiB / 63 TiB avail
        pgs:     21624/131171 objects degraded (16.485%)
                 878 active+clean
                 522 active+undersized+degraded
                 241 active+undersized

      io:
        client:   6.2 KiB/s rd, 280 KiB/s wr, 2 op/s rd, 49 op/s wr
    ```

1. Remove Ceph OSDs.

    The `ceph osd tree` capture indicated that there are down OSDs on `ncn-s003`.

     ```screen
     ceph osd tree down
     ```

     Example output:

     ```text
     ID  CLASS  WEIGHT    TYPE NAME          STATUS  REWEIGHT  PRI-AFF
     -1         62.87750  root default
     -9         10.47958      host ncn-s003
     36    ssd   1.74660          osd.36       down   1.00000  1.00000
     37    ssd   1.74660          osd.37       down   1.00000  1.00000
     38    ssd   1.74660          osd.38       down   1.00000  1.00000
     39    ssd   1.74660          osd.39       down   1.00000  1.00000
     40    ssd   1.74660          osd.40       down   1.00000  1.00000
     41    ssd   1.74660          osd.41       down   1.00000  1.00000
     ```

    1. Remove the OSD references to allow the rebuild to re-use the original OSD references on the drives.
       By default, if the OSD reference is not removed, then there will still a reference to them in the CRUSH map.
       This will result in OSDs that no longer exist appearing to be down.

        The following command assumes the variables from [the prerequisites section](Rebuild_NCNs.md#Prerequisites) are set.

        This must be run from a `ceph-mon` node (ncn-s00[1/2/3])

        ```bash
        for osd in $(ceph osd ls-tree $NODE); do ceph osd destroy osd.$osd --force; ceph osd purge osd.$osd --force; done
        ```

        Example Output:

        ```screen
        destroyed osd.1
        purged osd.1
        destroyed osd.3
        purged osd.3
        destroyed osd.6
        purged osd.6
        destroyed osd.9
        purged osd.9
        ```

## Next Step

Proceed to the next step to [Identify Nodes and Update Metadata](Identify_Nodes_and_Update_Metadata.md). Otherwise, return to the main [Rebuild NCNs](Rebuild_NCNs.md) page.
