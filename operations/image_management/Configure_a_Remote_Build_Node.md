# IMS Remote Builds 

Typically IMS jobs are run within Kubernetes (K8S) pods on the cluster's worker nodes. With csm-1.5.1,
IMS now has the ability to run these jobs on a dedicated, repurposed compute node rather than within
the K8S pods. There are two primary reasons to choose to run jobs on a remote build node.

1. Resources available to the K8S workers.

The IMS jobs creating and customizing images can consume a lot of resources within the K8S cluster,
particularly as the image sizes get larger. If the jobs are offloaded to remote nodes, most of that
resource pressure can be shifted to the remote node. This can be particularly important if the
workers in the cluster are already under load stress.

2. Performance due to cross archetecture builds.

All K8S worker nodes are running on x86_64 hardware. While IMS is installed with a method of generating
aarch64 image builds via emulation, this method is best suited for minimal or barebones image builds. The
emulation is done through a Kata VM running a QEMU translator. The process of translating x86_64
to aarch64 instructions has a serious performance impact. When running the job on a remote node, it will
run on the native archetecture of the remote node. Running aarch64 image builds on an aarch64 remote node
can see over a 10x performance increase versus running the same job under emulation.

## Prerequisites 
- Available compute node
- CSM 1.5.1 or higher

## Configuring a Remote Build Node

There are only two requirements for using a compute node as a remote build node:
- Have podman installed and configured
- Allow IMS access via ssh key

### Use an Existing Compute Node

This will add processes to the node being used as a remote build node. The system administrator
will need to decide if this compute node needs to be removed from the workload manager while being
used to work with images, or if it can still run compute jobs while building images.

1. Install or verify podman is installed

    SSH into your compute node.
    (`ncn-mw#`)
    ```bash
    ssh $XNAME
    ```
    Verify podman exists on the system
    ```bash
    podman
    ```
    If podman is installed on the system the output should start with 
    ```bash
    podman
    Manage pods, containers and images

    Usage:
    podman [options] [command]
    ```

    If the output is not as expected you will need to make sure the appropriate Nexus repositories are present on the system to facilitate the package installation.
    ** Note fields within <> require that you modify the version based upon your service pack version and the architecture will be either x86_64 or aarch64 for the platform architecture you are targeting.
    ```bash
    zypper addrepo --priority 4 https://packages.local/repository/SUSE-SLE-Module-Basesystem-15-SP<version>-<architecture>-Pool/ SUSE-SLE-Module-Basesystem-15-sp<version>-<architecture>-Pool
    zypper addrepo --priority 4 https://packages.local/repository/SUSE-SLE-Module-Containers-15-SP<version>-<architecture>-Pool/ SUSE-SLE-Module-Containers-15-sp<version>-<architecture>-Pool
    ```
    ```bash
    zypper in podman
    ```

2. Install the IMS ssh key.

    - get ssh key from K8S secrets
    - copy into node's ~/.ssh/autorized_keys file

    (`ncn-mw#`)
    ```bash
    kubectl -n services get cm cray-ims-remote-keys -o yaml
    ```
    From within the compute node
    ```bash 
    vi ~/.ssh/authorized_keys
    ```
    Add a new line and paste in the public key copied from the previous step.

### Create a Barebones IMS Builder Image

If there is no existing compute image to boot a node with, one can be created based on the barebones
image that is installed with CSM.

1. (`ncn-mw#`) Find the appropriate barebones image.
    ```bash
    cray ims images list | grep -B 5 compute-csm.*aarch64
    ```
    Expected output will resemble:
    ```text
    [[results]]
    arch = "aarch64"
    created = "2024-01-10T22:48:48.277640+00:00"
    id = "f9de6a5b-b49d-4e7a-b78f-18599a8e61f9"
    name = "compute-csm-1.5-5.2.47-aarch64"
    ```

2. Create a CFS configuration to customize the barebones image.

    Store the id of the arm compute image in the previous step and create a cfs configuration resembling the following. 

    ```json
    {
        "last_updated": "2020-09-22T19:56:32Z",
        "layers": [
            {
                "clone_url": "https://api-gw-service-nmn.local/vcs/cray/configmanagement.git",
                "commit": "01b8083dd89c394675f3a6955914f344b90581e2",
                "playbook": "ims-computes.yml"
            }
        ],
        "name": "ims-config"
    }
    ```

3. Use CFS to customize the barebones image.

    After posting your cfs configuration you will use it to customize the image id retrieved in the previous step.

    (`ncn-mw#`)
    ```bash
    cray cfs sessions create --target-group Application <IMS ID of your image> --target-image-map <IMS ID of your image> <name you want your new image to have in IMS> --target-definition image --name <pick a name for your CFS session> --configuration-name <name of the CFS configuration you created in the previous step>
    ```

4. Boot the compute node with the customized image

    Once the cfs customization is finished, the image is ready to be booted. Create a bos session template referencing that image and use it to boot an arm node.

    ```json
    {
        "boot_sets": {
            "compute": {
	            "kernel_parameters": "ip=dhcp quiet spire_join_token=${SPIRE_JOIN_TOKEN} root=live:s3://boot-images/<image id>/rootfs nmd_data=url=s3://boot-images/<image id>/rootfs,etag=<etag>",
                "node_roles_groups": [ "Compute"],
                "etag": "<etag>",
	            "arch": "ARM",
                "path": "s3://boot-images/<image id>/manifest.json",
                "rootfs_provider": "",
                "rootfs_provider_passthrough": "",
                "type": "s3"
            }
        }
    }
    ```

5. Optionally lock the compute node to prevent unintended reboots of the compute node.

    Once the image is booted and operational you may also possibly look into the possiblity of adding an HSM lock to that node. This will prevent unwanted or accidental reboots or poweroffs.
    (`ncn-mw#`)
    ```bash
    cray hsm locks lock create --component-ids <compute node XNAME>
    ```

    The lock can be removed at anytime via
    ```bash
    cray hsm locks unlock create --component-ids <compute node XNAME>
    ```

6. Add storage to the remote build node.

    By default compute nodes have limited storage. While executing small image builds may be possible, you will not be able to build larger images without additonal
    storage being available to the ims builder node. We can achieve this by mounting ceph storage into the ims builder node.

    Below are a set of commands that should provide the ims builder node with the storage that it needs to execute larger image builds 

    From within IMS remote builder 
    ```bash
    nid001030:~ # egrep 'NETCONFIG_DNS_STATIC_SERVERS|NETCONFIG_DNS_STATIC_SEARCHLIST' /etc/sysconfig/network/config
    NETCONFIG_DNS_STATIC_SEARCHLIST="search nmn mtl hmn"
    NETCONFIG_DNS_STATIC_SERVERS="10.92.100.225"

    nid001030:~ # netconfig update -f
    nid001030:~ # zypper install -y ceph-common
    ```

    (`ncn-mw#`)
    ```bash
    scp /etc/ceph/ceph.conf <compute node XNAME>:/etc/ceph/ceph.conf
    scp /etc/ceph/ceph.client.admin.keyring <compute node XNAME>:/etc/ceph/
    ```

    From within IMS remote builder
    ```bash
    nid001030:~ # RBD=$( rbd map kube/buildcache --id kube --keyring /etc/ceph/ceph.client.kube.keyring )
    nid001030:~ # echo $RBD
    /dev/rbd1

    nid001030:~ # mkdir -p /mnt/cache
    nid001030:~ # mount /dev/rbd1 /mnt/cache

    nid001030:~ # mkdir /mnt/cache/tmp
    nid001030:~ # mount --bind /mnt/cache/tmp /tmp
    nid001030:~ # mkdir -p /mnt/cache/var/lib/containers/storage/overlay/
    nid001030:~ # mount --bind /mnt/cache/var/lib/containers/storage/overlay/ /var/lib/containers/storage/overlay/
    ```

### Adding and Removing Remote Build Nodes to IMS 

    Once your node has been configured with all of the above steps, the final step is to register that node with IMS so
    that it knows that it can be used for image builds.

    Register a remote build node for ims
    ```bash
    cray ims remote-build-nodes create --xname <compute node xname>
    ```
    Removing a remote build node from ims 
    ```bash
    cray ims remote-build-nodes delete <compute node xname>
    ```bash
    List available remote build nodes 
    ```bash
    cray ims remote-build-nodes list
    ```

    Once complete you are all set to go. IMS will automatically use a remote build node for arm builds if one is made
    available so there will be no change to previous commands for either create or customize jobs.


