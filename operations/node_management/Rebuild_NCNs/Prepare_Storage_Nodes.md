# Prepare Storage Nodes

Prepare a storage node before rebuilding it.

**IMPORTANT:** All of the output examples may not reflect the cluster status where this operation is being performed. For example, if this is a rebuild in place, then Ceph components will not be reporting down, in contrast to a failed node rebuild.

## Prerequisites

When rebuilding a node, make sure that `/srv/cray/scripts/common/storage-ceph-cloudinit.sh` and `/srv/cray/scripts/common/pre-load-images.sh` have been removed from the `runcmd` in BSS.

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

    m001_ip=$(host ncn-m001 | awk '{ print $NF }')
    ssh-keygen -R ncn-m001 -f ~/.ssh/known_hosts > /dev/null 2>&1
    ssh-keygen -R ${m001_ip} -f ~/.ssh/known_hosts > /dev/null 2>&1
    ssh-keyscan -H "ncn-m001,${ncn_ip}" >> ~/.ssh/known_hosts

    nexus_username=$(ssh ncn-m001 'kubectl get secret -n nexus nexus-admin-credential --template={{.data.username}} | base64 --decode')
    nexus_password=$(ssh ncn-m001 'kubectl get secret -n nexus nexus-admin-credential --template={{.data.password}} | base64 --decode')

    ssh_options="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
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
            ssh $storage_node ${ssh_options} "ceph config set mgr $to_configure $nexus_location"
            if [[ $? == 0 ]]; then
              break
            fi
        done
        
        # run upgrade if mgr
        if [[ $name == "mgr" ]]; then
          for storage_node in "ncn-s001" "ncn-s002" "ncn-s003"; do
            ssh $storage_node ${ssh_options} "ceph orch upgrade start --image $nexus_location"
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
        error=$(ssh $storage_node ${ssh_options} "ceph orch upgrade status --format json | jq '.message' | grep Error")
        if [[ -n $error ]]; then
          echo "Error: there was an issue with the upgrade. Run 'ceph orch upgrade status' from ncn-s00[1/2/3]."
          exit 1
        fi
        if [[ $(ssh $storage_node ${ssh_options} "ceph orch upgrade status --format json | jq '.in_progress'") != "true" ]]; then
          echo "Upgrade complete"
          success=true
          break
        else
          int=$(( $int + 1 ))
          sleep 10
        fi
      done
    done
    if ! $success; then
      echo "Error completing 'ceph orch upgrade'. Check upgrade status by running 'ceph orch upgrade status' from ncn-s00[1/2/3]."
      exit 1 
    fi

    # restart daemons
    for daemon in "prometheus" "node-exporter" "alertmanager" "grafana"; do
      daemons_to_restart=$(ceph --name client.ro orch ps | awk '{print $1}' | grep $daemon)
      for each in $daemons_to_restart; do
        for storage_node in "ncn-s001" "ncn-s002" "ncn-s003"; do
            ssh $storage_node ${ssh_options} "ceph orch daemon redeploy $each"
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

1. Check the OSD status, weight, and location:

    ```bash
    ceph osd tree
    ```

    Example output:

    ```text
    ID  CLASS  WEIGHT    TYPE NAME          STATUS  REWEIGHT  PRI-AFF
    -1         62.87558  root default
    -5         20.95853      host ncn-s001
    2    ssd   3.49309          osd.2          up   1.00000  1.00000
    5    ssd   3.49309          osd.5          up   1.00000  1.00000
    6    ssd   3.49309          osd.6          up   1.00000  1.00000
    9    ssd   3.49309          osd.9          up   1.00000  1.00000
    12   ssd   3.49309          osd.12         up   1.00000  1.00000
    16   ssd   3.49309          osd.16         up   1.00000  1.00000
    -3         20.95853      host ncn-s002
    0    ssd   3.49309          osd.0          up   1.00000  1.00000
    3    ssd   3.49309          osd.3          up   1.00000  1.00000
    7    ssd   3.49309          osd.7          up   1.00000  1.00000
    10   ssd   3.49309          osd.10         up   1.00000  1.00000
    13   ssd   3.49309          osd.13         up   1.00000  1.00000
    15   ssd   3.49309          osd.15         up   1.00000  1.00000
    -7         20.95853      host ncn-s003
    1    ssd   3.49309          osd.1          up   1.00000  1.00000
    4    ssd   3.49309          osd.4          up   1.00000  1.00000
    8    ssd   3.49309          osd.8          up   1.00000  1.00000
    11   ssd   3.49309          osd.11         up   1.00000  1.00000
    14   ssd   3.49309          osd.14         up   1.00000  1.00000
    17   ssd   3.49309          osd.17         up   1.00000  1.00000

1. If the node is up, then stop and disable all the Ceph services on the node being rebuilt.

    (`ncn-s#`) On the node being rebuilt, run:

    ```bash
    for service in $(cephadm ls |jq -r '.[].systemd_unit'); do systemctl stop $service; systemctl disable $service; done
    ```

    Example output:

    ```screen
    Removed /etc/systemd/system/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6.target.wants/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6@rgw.site1.ncn-s003.iibwgo.service.
    Removed /etc/systemd/system/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6.target.wants/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6@osd.14.service.
    Removed /etc/systemd/system/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6.target.wants/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6@osd.1.service.
    Removed /etc/systemd/system/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6.target.wants/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6@mds.cephfs.ncn-s003.ijrnef.service.
    Removed /etc/systemd/system/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6.target.wants/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6@osd.17.service.
    Removed /etc/systemd/system/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6.target.wants/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6@osd.11.service.
    Removed /etc/systemd/system/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6.target.wants/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6@crash.ncn-s003.service.
    Removed /etc/systemd/system/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6.target.wants/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6@mgr.ncn-s003.gasosn.service.
    Removed /etc/systemd/system/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6.target.wants/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6@mon.ncn-s003.service.
    Removed /etc/systemd/system/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6.target.wants/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6@node-exporter.ncn-s003.service.
    Removed /etc/systemd/system/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6.target.wants/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6@osd.8.service.
    Removed /etc/systemd/system/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6.target.wants/ceph-4c9e9d74-a208-11ed-b008-98039bb427f6@osd.4.service.
    ```

1. Re-check the OSD status, weight, and location:

    ```bash
    ceph osd tree
    ```

    Example output:

    ```text
    ID  CLASS  WEIGHT    TYPE NAME          STATUS  REWEIGHT  PRI-AFF
    -1         62.87558  root default
    -5         20.95853      host ncn-s001
    2    ssd   3.49309          osd.2          up   1.00000  1.00000
    5    ssd   3.49309          osd.5          up   1.00000  1.00000
    6    ssd   3.49309          osd.6          up   1.00000  1.00000
    9    ssd   3.49309          osd.9          up   1.00000  1.00000
    12   ssd   3.49309          osd.12         up   1.00000  1.00000
    16   ssd   3.49309          osd.16         up   1.00000  1.00000
    -3         20.95853      host ncn-s002
    0    ssd   3.49309          osd.0          up   1.00000  1.00000
    3    ssd   3.49309          osd.3          up   1.00000  1.00000
    7    ssd   3.49309          osd.7          up   1.00000  1.00000
    10   ssd   3.49309          osd.10         up   1.00000  1.00000
    13   ssd   3.49309          osd.13         up   1.00000  1.00000
    15   ssd   3.49309          osd.15         up   1.00000  1.00000
    -7         20.95853      host ncn-s003
    1    ssd   3.49309          osd.1        down   1.00000  1.00000
    4    ssd   3.49309          osd.4        down   1.00000  1.00000
    8    ssd   3.49309          osd.8        down   1.00000  1.00000
    11   ssd   3.49309          osd.11       down   1.00000  1.00000
    14   ssd   3.49309          osd.14       down   1.00000  1.00000
    17   ssd   3.49309          osd.17       down   1.00000  1.00000
    ```

1. Check the status of the Ceph cluster:

    ```screen
    ceph -s
    ```

    Example output:

    ```text
      cluster:
        id:     4c9e9d74-a208-11ed-b008-98039bb427f6
        health: HEALTH_WARN
                1/3 mons down, quorum ncn-s001,ncn-s002
                6 osds down
                1 host (6 osds) down
                Degraded data redundancy: 34257/102773 objects degraded (33.333%), 370 pgs degraded, 352 pgs undersized

      services:
        mon: 3 daemons, quorum ncn-s001,ncn-s002 (age 56s), out of quorum: ncn-s003
        mgr: ncn-s002.amfitm(active, since 43m), standbys: ncn-s001.rytusj
        mds: 1/1 daemons up, 1 hot standby
        osd: 18 osds: 12 up (since 55s), 18 in (since 13h)
        rgw: 2 daemons active (2 hosts, 1 zones)

      data:
        volumes: 1/1 healthy
        pools:   13 pools, 553 pgs
        objects: 34.26k objects, 58 GiB
        usage:   173 GiB used, 63 TiB / 63 TiB avail
        pgs:     34257/102773 objects degraded (33.333%)
                370 active+undersized+degraded
                159 active+undersized
                24  active+clean

      io:
        client:   8.7 KiB/s rd, 353 KiB/s wr, 3 op/s rd, 53 op/s wr
    ```

1. Remove Ceph OSDs.

    The `ceph osd tree` capture indicated that there are down OSDs on `ncn-s003`.

     ```screen
     ceph osd tree down
     ```

     Example output:

     ```text
     ID  CLASS  WEIGHT    TYPE NAME          STATUS  REWEIGHT  PRI-AFF
     -1         62.87758  root default
     -7         20.95853      host ncn-s003
      1    ssd   3.49309          osd.1        down   1.00000  1.00000
      4    ssd   3.49309          osd.4        down   1.00000  1.00000
      8    ssd   3.49309          osd.8        down   1.00000  1.00000
      11   ssd   3.49309          osd.11       down   1.00000  1.00000
      14   ssd   3.49309          osd.14       down   1.00000  1.00000
      17   ssd   3.49309          osd.17       down   1.00000  1.00000
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
        destroyed osd.4
        purged osd.4
        destroyed osd.6
        purged osd.6
        destroyed osd.11
        purged osd.11
        destroyed osd.14
        purged osd.14
        destroyed osd.17
        purged osd.17
        ```

## Next Step

Proceed to the next step to [Identify Nodes and Update Metadata](Identify_Nodes_and_Update_Metadata.md). Otherwise, return to the main [Rebuild NCNs](Rebuild_NCNs.md) page.
