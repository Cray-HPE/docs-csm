# Configure a Remote Build Node

Configure or create an IMS remote build node for use for image builds.

* [Prerequisites](#prerequisites)
* [Overview](#overview)
* [Configuring a remote build node](#configuring-a-remote-build-node)
* [Use an existing compute node](#use-an-existing-compute-node)
* [Create a barebones IMS builder image](#create-a-barebones-ims-builder-image)
* [Adding storage to a remote build node](#adding-storage-to-a-remote-build-node)
* [Adding and removing an HSM lock](#adding-and-removing-an-hsm-lock)
* [Adding remote build nodes to IMS](#adding-remote-build-nodes-to-ims)
* [Removing remote build nodes from IMS](#removing-remote-build-nodes-from-ims)
* [Listing remote build nodes in IMS](#listing-remote-build-nodes-in-ims)

## Prerequisites

* Available compute node
* CSM `1.5.1` or higher

## Overview

Typically IMS jobs are run within Kubernetes (K8S) pods on the cluster's worker nodes. With CSM `1.5.1`,
IMS now has the ability to run these jobs on a dedicated, repurposed compute node rather than within
the K8S pods. There are two primary reasons to choose to run jobs on a remote build node.

1. Resources available to the K8S workers.

    The IMS jobs creating and customizing images can consume a lot of resources within the K8S cluster,
    particularly as the image sizes get larger. If the jobs are offloaded to remote nodes, most of that
    resource pressure can be shifted to the remote node. This can be particularly important if the
    workers in the cluster are already under load stress.

1. Performance penalty of cross architecture builds.

    All K8S worker nodes are running on `x86_64` hardware. While IMS is installed with a method of generating
    `aarch64` image builds via emulation, this method is best suited for minimal or barebones image builds. The
    emulation is done through a Kata VM running a QEMU translator. The process of translating `x86_64`
    to `aarch64` instructions has a serious performance impact. When running the job on a remote node, it will
    run on the native architecture of the remote node. Running `aarch64` image builds on an `aarch64` remote node
    can see over a 10 fold performance increase versus running the same job under emulation.

Any job with an architecture matching a defined remote build node will be run remotely with no other changes
needed. If there are multiple remote build nodes with the same architecture, there is a basic load balancing
algorithm in place to spread the workload between all active remote build nodes.

When a new IMS job is created, the defined remote build nodes are checked to ensure SSH access is available
and the required software is present on the node. If either of these checks fail, the node will not be used
for the new job. If all matching remote nodes fail this check, the job will be created to run within the
K8S environment as a standard local job. There is output in the `cray-ims` pod that will indicate why defined
remote nodes are not being used if these checks fail.

See [Troubleshoot Remote Build Node](Troubleshoot_Remote_Build_Node.md) for issues running remote jobs.

## Configuring a remote build node

There are only two requirements for using a compute node as a remote build node:

* Have Podman installed and configured
* Allow IMS access via SSH key

### Use an existing compute node

This will add processes to the node being used as a remote build node. The system administrator
will need to decide if this compute node needs to be removed from the workload manager while being
used to work with images, or if it can still run compute jobs while building images.

1. (`cn#`) Install Podman or verify Podman is installed on the remote build node.

    Verify Podman exists on the system.

    ```bash
    podman
    ```

    Example output:

    ```text
    podman
    Manage pods, containers and images

    Usage:
    podman [options] [command]
    ```

    If the output is not as expected, make sure the appropriate Nexus repositories are present on the system
    to facilitate the package installation.

    ** Note: Fields within `<>` must be modified based upon the service pack version; and the architecture will
    be either `x86_64` or `aarch64`, based on the target platform architecture.

    1. Add the necessary repositories to install Podman.

        ```bash
        zypper addrepo --priority 4 https://packages.local/repository/SUSE-SLE-Module-Basesystem-15-SP<version>-<architecture>-Pool/ SUSE-SLE-Module-Basesystem-15-sp<version>-<architecture>-Pool
        zypper addrepo --priority 4 https://packages.local/repository/SUSE-SLE-Module-Containers-15-SP<version>-<architecture>-Pool/ SUSE-SLE-Module-Containers-15-sp<version>-<architecture>-Pool
        ```

    1. Install Podman.

        ```bash
        zypper in podman
        ```

1. Install the IMS SSH key.

    1. (`ncn-mw#`) Retrieve the public key from the IMS ConfigMap.

        ```bash
        kubectl -n services get cm cray-ims-remote-keys -o yaml | grep -A 1 public_key
        ```

        Example output (actual key will be different):

        ```yaml
        public_key: |
        ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQABABhBI7zwN4rTeBHyIPKTe2ARrmTvfDWhnh4ZBu+u/LyHE8f5Fjyo8xtvqeUjUm95OLfGtr/PDbYDoX3GltfvyjzOxNt9hBWZ3Zzbr4H0Y8go4dp/mg8OFzLMYbJWTdTS8B/Rw==
        ```

    1. (`cn#`) Edit `authorized_keys` file.

        Add a new line and paste in the public key copied from the previous step.

        ```bash
        vi ~/.ssh/authorized_keys
        ```

### Create a barebones IMS builder image

If there is no existing compute image to boot a node with, one can be created based on the barebones
image that is installed with CSM.

1. (`ncn-mw#`) Find the latest CSM install on the system.

    ```bash
    kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}'
    ```

    Expected output will contain all the CSM versions that have been installed on the system.
    Take note of the most recent, which should look similar to the following:

    ```yaml
    1.5.1:
        configuration:
            clone_url: https://vcs.cmn.mug.hpc.amslabs.hpecorp.net/vcs/cray/csm-config-management.git
            commit: 545dd8f97645ee6882a8cef2f7dfdf25a63c1d8e
            import_branch: cray/csm/1.16.28
            import_date: 2024-03-22 12:47:14.937124
            ssh_url: git@vcs.cmn.mug.hpc.amslabs.hpecorp.net:cray/csm-config-management.git
        images:
            compute-csm-1.5-5.2.55-aarch64:
            id: 02c18757-b546-4a9f-9eae-891928bbbbb9
            compute-csm-1.5-5.2.55-x86_64:
            id: f6d9cfc7-9291-4c46-8350-c252b919d396
            cray-shasta-csm-sles15sp5-barebones-csm-1.5:
            id: 771971b5-125a-426d-8bd4-0a2a0b8e23cf
            secure-kubernetes-5.2.54-x86_64.squashfs:
            id: aea9f96d-20ba-4194-b8d4-0047803dd146
            secure-storage-ceph-5.2.54-x86_64.squashfs:
            id: 24aa8dbb-6f21-44fe-8e82-25e35802937e
        recipes:
            cray-shasta-csm-sles15sp5-barebones-csm-1.5-aarch64:
            id: 156f86ca-ebda-4bcc-b342-32ebbb99ee76
            cray-shasta-csm-sles15sp5-barebones-csm-1.5-x86_64:
            id: fca72545-338d-4220-88f7-7807d4c2c7e5
    ```

1. (`ncn-mw#`) Find the appropriate barebones image and record the id.

    In the output above, look for the barebones compute image that has the name in the format
    `compute-csm-<CSM_VER>-<IMAGE_VER>-<IMAGE_ARCH>` that matches the architecture of the remote
    build node being configured. Take note of the `id` for this image.

    ```bash
    BAREBONES_IMAGE_ID=<images.id-from-above-information>
    ```

    Be sure to use the actual id of the image, not the id value from the examples in this documentation.

1. (`ncn-mw#`) Create a CFS configuration to customize the barebones image.

    1. Set environment variables.

        Set environment variables for the configuration information from the above CSM installed version, and
        set an environment variable for the name of the CFS configuration.

        > NOTE: Change the host for the `clone_url` to `api-gw-service-nmn.local` in the first environment
        > variable below, because access will be from inside the Kubernetes service mesh.

        ```bash
        CLONE_URL=<configuration.clone_url-from-above-information>
        COMMIT_ID=<configuration.commit-from-above-information>
        IMS_REMOTE_CFS_CONFIGURATION=remote-ims-node
        ```

    1. Create a CFS configuration file using the above values.

        ```bash
        cat << EOF > cfs_config.json
        {
            "layers": [
                {
                    "clone_url": "$CLONE_URL",
                    "commit": "$COMMIT_ID",
                    "playbook": "ims_computes.yml"
                }
            ]
        }
        EOF
        ```

    1. Use the file generated above to create a new CFS configuration.

        ```bash
        cray cfs v3 configurations update $IMS_REMOTE_CFS_CONFIGURATION --file ./cfs_config.json --format json
        ```

        Expected output will be something similar to:

    ```json
        {
            "last_updated": "2024-04-23T16:44:55Z",
            "layers": [
                {
                "clone_url": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
                "commit": "545dd8f97645ee6882a8cef2f7dfdf25a63c1d8e",
                "playbook": "ims_computes.yml"
                }
            ],
            "name": "remote-ims-node"
        }
        ```

1. (`ncn-mw#`) Use CFS to customize the barebones image.

    Use the new CFS configuration to customize the image whose ID was retrieved in an
    earlier step.

    1. Set environment variables with names for the new IMS image and the CFS session.

        ```bash
        NEW_IMAGE_NAME=ims-remote-image-x86_64
        CFS_SESSION_NAME=build-ims-remote-image-x86
        ```

    1. Create the CFS session.

        ```bash
        cray cfs sessions create --target-group Application $BAREBONES_IMAGE_ID \
            --target-image-map $BAREBONES_IMAGE_ID $NEW_IMAGE_NAME \
            --target-definition image --name $CFS_SESSION_NAME \
            --configuration-name $IMS_REMOTE_CFS_CONFIGURATION
        ```

    1. Follow the CFS session to ensure that it completes without errors.

    1. When complete, record the image id of the new image.

        ```bash
        cray cfs sessions describe $CFS_SESSION_NAME | jq '.status.artifacts'
        ```

        Example output:

        ```json
        [
            {
                "image_id": "adb5abcb-45c8-4352-bc36-df47220d13e1",
                "result_id": "295aa9a1-f56c-4307-acad-21b58d02321c",
                "type": "ims_customized_image"
            }
        ]
        ```

    1. Create a new environment variable to store this new image id.

        ```bash
        REMOTE_IMS_NODE_IMAGE_ID=<result_id_from_above_output>
        ```

    1. Look up the `etag` of the resulting image id.

        ```bash
        cray ims images describe $REMOTE_IMS_NODE_IMAGE_ID --format json
        ```

        Example output:

        ```json
        {
            "arch": "x86_64",
            "created": "2024-04-24T12:40:30.786609+00:00",
            "id": "295aa9a1-f56c-4307-acad-21b58d02321c",
            "link": {
                "etag": "e93dacac642f1e3bffe3be275a090049",
                "path": "s3://boot-images/295aa9a1-f56c-4307-acad-21b58d02321c/manifest.json",
                "type": "s3"
            },
            "name": "compute-uss-1.0.1-8-csm-1.5.aarch64-516248"
        }
        ```

    1. Create a new environment variable for the `etag` in the above information.

        ```bash
        REMOTE_IMS_NODE_IMAGE_ETAG=<link_etag_from_above_output>
        ```

1. (`ncn-mw#`) Boot the compute node with the customized image.

    Once the CFS customization is finished, the image is ready to be booted. Create a BOS session template
    referencing that image and use it to boot the remote node.

    1. Create a file named `bos_template.json` with the following content.

        Replace `<REMOTE_IMS_NODE_IMAGE_ID>` (3 occurrences) with the value from above and
        `<REMOTE_IMS_NODE_IMAGE_ETAG>` (2 occurrences) with its value from above.
        Replace `<REMOTE_NODE_ARCH>` (1 occurrence) with `ARM` for an `aarch64` architecture,
        or with `X86` for an `x86_64` architecture.

        ```json
        {
            "boot_sets": {
                "compute": {
                    "kernel_parameters": "ip=dhcp quiet spire_join_token=${SPIRE_JOIN_TOKEN} root=live:s3://boot-images/<REMOTE_IMS_NODE_IMAGE_ID>/rootfs nmd_data=url=s3://boot-images/<REMOTE_IMS_NODE_IMAGE_ID>/rootfs,etag=<REMOTE_IMS_NODE_IMAGE_ETAG>",
                    "node_roles_groups": [ "Compute"],
                    "etag": "<REMOTE_IMS_NODE_IMAGE_ETAG>",
                    "arch": "<REMOTE_NODE_ARCH>",
                    "path": "s3://boot-images/<REMOTE_IMS_NODE_IMAGE_ID>/manifest.json",
                    "rootfs_provider": "",
                    "rootfs_provider_passthrough": "",
                    "type": "s3"
                }
            }
        }
        ```

    1. Create the BOS session template for this boot.

        ```bash
        IMS_REMOTE_BOS_SESSION_TEMPLATE=bos_ims_remote_node
        cray bos sessiontemplates create --file ./bos_template.json \
            --cfs-configuration $IMS_REMOTE_CFS_CONFIGURATION \
            $IMS_REMOTE_BOS_SESSION_TEMPLATE --format json
        ```

        Example output:

        ```json
        {
            "boot_sets": {
                "compute": {
                "arch": "X86",
                "etag": "9bbdebd4e51f32a2db8f8dd3e6124166",
                "kernel_parameters": "ip=dhcp quiet spire_join_token=${SPIRE_JOIN_TOKEN} root=live:s3://boot-images/f6d9cfc7-9291-4c46-8350-c252b919d396/rootfs nmd_data=url=s3://boot-images/f6d9cfc7-9291-4c46-8350-c252b919d396/rootfs,etag=9bbdebd4e51f32a2db8f8dd3e6124166",
                "node_roles_groups": [
                    "Compute"
                ],
                "path": "s3://boot-images/f6d9cfc7-9291-4c46-8350-c252b919d396/manifest.json",
                "rootfs_provider": "",
                "rootfs_provider_passthrough": "",
                "type": "s3"
                }
            },
            "name": "bos_ims_remote_node",
            "tenant": ""
        }
        ```

    1. Boot the node that is being used for remote IMS builds.

        If the node is currently booted, use `reboot`, otherwise (if the node is currently off) use `boot`.

        ```bash
        IMS_REMOTE_NODE_XNAME=<xname of compute node>
        cray bos sessions create --template-name "${IMS_REMOTE_BOS_SESSION_TEMPLATE}" \
            --operation boot --limit "${IMS_REMOTE_NODE_XNAME}"
        ```

    1. Wait for the node to boot and become available.

### Adding storage to a remote build node

By default compute nodes have limited storage. While executing small image builds may be possible,
it will not be possible to build larger images or multiple images concurrently without additional
storage being available to the IMS builder node. This can be achieved by mounting Ceph storage
directly into the IMS builder node.

Below is a procedure to provide the IMS builder node with additional storage.

1. Set an environment variable for the xname of the remote build node.

    ```bash
    IMS_REMOTE_NODE_XNAME=<xname of compute node>
    ```

1. (`ncn-mw#`) Describe the node management network load balancer and note the IP address of the unbound alias.

    ```bash
    cray sls networks describe NMNLB --format json | jq '.ExtraProperties.Subnets[].IPReservations[] | select(.Name | contains("unbound"))'
    ```

    Example output:

    ```json
    {
        "Aliases": [
            "unbound"
        ],
        "Comment": "unbound",
        "IPAddress": "10.92.100.225",
        "Name": "unbound"
    }
    ```

1. (`cn#`) Edit the network configuration on the remote build node.

    1. Edit the following fields contained within the file `/etc/sysconfig/network/config`.

        ```text
        NETCONFIG_DNS_STATIC_SEARCHLIST="nmn mtl hmn"
        NETCONFIG_DNS_STATIC_SERVERS="<IP_ADDRESS_FROM_PREVIOUS_STEP>"
        ```

    1. Update the network configuration with the new settings:

        ```bash
        netconfig update -f
        ```

1. (`cn#`) Install `ceph-common`.

    ```bash
    zypper install -y ceph-common
    ```

    Expected output will be something like:

    ```text
    Loading repository data...
    Reading installed packages...
    Resolving package dependencies...

    The following 26 NEW packages are going to be installed:
    ceph-common libcephfs2 libefa1 libfmt8 libibverbs libibverbs1 libleveldb1 liblttng-ust0 libmlx4-1 libmlx5-1
    liboath0 librados2 librbd1 librdmacm1 librgw2 libtcmalloc4 liburcu6 oath-toolkit-xml python3-ceph-argparse
    python3-ceph-common python3-cephfs python3-PrettyTable python3-rados python3-rbd python3-rgw rdma-core

    26 new packages to install.

    ...

    22/26) Installing: libcephfs2-16.2.11.58+g38d6afd3b78-150400.3.6.1.x86_64 ...[done]
    (23/26) Installing: python3-rgw-16.2.11.58+g38d6afd3b78-150400.3.6.1.x86_64 ...[done]
    (24/26) Installing: python3-rbd-16.2.11.58+g38d6afd3b78-150400.3.6.1.x86_64 ...[done]
    (25/26) Installing: python3-cephfs-16.2.11.58+g38d6afd3b78-150400.3.6.1.x86_64 ...[done]
    (26/26) Installing: ceph-common-16.2.11.58+g38d6afd3b78-150400.3.6.1.x86_64 ...[done]
    Running post-transaction scripts ...[done]
    ```

1. (`ncn-mw#`) Copy the Ceph configuration and client admin keyring to the remote build node.

    ```bash
    scp /etc/ceph/ceph.conf ${IMS_REMOTE_NODE_XNAME}:/etc/ceph/ceph.conf
    scp /etc/ceph/ceph.client.admin.keyring ${IMS_REMOTE_NODE_XNAME}:/etc/ceph/
    scp /etc/ceph/ceph.client.admin-tools.keyring ${IMS_REMOTE_NODE_XNAME}:/etc/ceph/
    scp /etc/ceph/ceph.client.kube.keyring ${IMS_REMOTE_NODE_XNAME}:/etc/ceph/
    ```

1. (`cn#`) Configure Ceph storage on the remote build node.

    1. Create the RBD.

        If the RBD has not been created previously, create it now. If it has already been created
        it does not need to be created again.

        ```bash
        rbd create kube/buildcache --size 1000G
        rbd feature disable kube/buildcache object-map fast-diff deep-flatten
        ```

    1. Set up the device.

        ```bash
        RBD=$( rbd map kube/buildcache --id kube --keyring /etc/ceph/ceph.client.kube.keyring )
        echo $RBD
        ```

        Example output:

        ```text
        /dev/rbd1
        ```

    1. Format the RBD.

        If the RBD was just created, format it now. If it was already created and formatted previously
        it does not need to be formatted again.

        ```bash
        mkfs.ext4 $RBD
        ```

        Expected output:

        ```text
        mke2fs 1.46.4 (18-Aug-2021)
        Discarding device blocks: done
        Creating filesystem with 262144000 4k blocks and 65536000 inodes
        Filesystem UUID: 4841aa0a-603f-4e3b-94c4-ee30dfe5c276
        Superblock backups stored on blocks:
            32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
            4096000, 7962624, 11239424, 20480000, 23887872, 71663616, 78675968,
            102400000, 214990848

        Allocating group tables: done
        Writing inode tables: done
        Creating journal (262144 blocks): done
        Writing superblocks and filesystem accounting information: done
        ```

    1. Create and mount the required directories for remote build jobs.

        ```bash
        mkdir -p /mnt/cache
        mount "${RBD}" /mnt/cache

        mkdir -p /mnt/cache/tmp
        mount --bind /mnt/cache/tmp /tmp

        mkdir -p /mnt/cache/var/lib/containers/
        mount --bind /mnt/cache/var/lib/containers/ /var/lib/containers/
        
        mkdir -p /mnt/cache/var/tmp
        mount --bind /mnt/cache/var/tmp/ /var/tmp/
        ```

### Adding and removing an HSM lock

NOTE: This is an optional step.

If the node is rebooted while a remote build is running, that job will fail. Additionally, if the node
is booted into a different image, the node will no longer work for remote builds until it is booted back
into the remote build image, or if using an existing compute image, the manual configuration steps that
allow it to work as a remote build node will be removed.

To prevent accidental reboots of the remote build node, a lock may be applied through HSM that will
protect the node from boots and power operations. Note that if the node is locked, operations that
include that node will fail.

1. (`ncn-mw#`) Create environment variable for the remote node's xname.

    ```bash
    'IMS_REMOTE_NODE_XNAME=<xname of remote node>
    ```

1. (`ncn-mw#`) Lock the compute node.

    ```bash
    cray hsm locks lock create --component-ids "${IMS_REMOTE_NODE_XNAME}" --format json
    ```

    Expected output will be something like:

    ```json
    {
        "Counts": {
            "Total": 1,
            "Success": 1,
            "Failure": 0
        },
        "Success": {
            "ComponentIDs": [
            "x3000c0s19b4n0"
            ]
        },
        "Failure": []
    }
    ```

1. (`ncn-mw#`) Check the lock status of a node.

    ```bash
    cray hsm locks status create --component-ids "${IMS_REMOTE_NODE_XNAME}" --format json
    ```

    Expected output will be something like:

    ```json
    {
        "Components": [
            {
            "ID": "x3000c0s19b4n0",
            "Locked": true,
            "Reserved": false,
            "ReservationDisabled": false
            }
        ]
    }
    ```

1. (`ncn-mw#`) Unlock the compute node.

    When done with the remote build node, remove the lock to allow reboot and power operations
    on the node.

    ```bash
    cray hsm locks unlock create --component-ids "${IMS_REMOTE_NODE_XNAME}" --format json
    ```

    Expected output will be something like:

    ```json
    {
        "Counts": {
            "Total": 1,
            "Success": 1,
            "Failure": 0
        },
        "Success": {
            "ComponentIDs": [
            "x3000c0s19b4n0"
            ]
        },
        "Failure": []
    }
    ```

For more information, see [Manage HSM Locks](../hardware_state_manager/Manage_HMS_Locks.md).

### Adding remote build nodes to IMS

Once a node has been configured with all of the above steps, the final step is to register
that node with IMS, allowing it to be used for image builds.

1. (`ncn-mw#`) Create environment variable for the remote node's xname.

    ```bash
    'IMS_REMOTE_NODE_XNAME=<xname of remote node>
    ```

1. (`ncn-mw#`) Add the remote build node to IMS.

    ```bash
    cray ims remote-build-nodes create --xname "${IMS_REMOTE_NODE_XNAME}" --format json
    ```

    Expected output will be something like:

    ```json
    {
        "xname": "x3000c0s19b4n0"
    }
    ```

### Remove remote build nodes from IMS

(`ncn-mw#`) Remove a remote build node from IMS.

```bash
cray ims remote-build-nodes delete "${IMS_REMOTE_NODE_XNAME}"
```

There is no expected output from this operation.

### Listing remote build nodes in IMS

(`ncn-mw#`) List available remote build nodes in IMS.

```bash
cray ims remote-build-nodes list --format json
```

Expected output will be something like:

```json
[
    {
        "xname": "x3000c0s19b4n0"
    }
]
```
