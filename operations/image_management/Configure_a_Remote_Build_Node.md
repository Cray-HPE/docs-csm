# IMS Remote Builds 

While IMS comes shipped with a method of generating arm64 image builds via emulation, this method is best suited for minimal or barebones image builds
due to the speed limitations that are imposed when trying to translate x86 instructions to the arm64 instruction set via QEMU namespace translation.
This is where IMS remote builds come into play. By leveraging arm hardware at your disposal, a 10x speed increase can be observed by performing image builds and customization as opposed to emulation.

## Prerequisites 
- arm based compute node
- ceph storage space 
- metal compute image 
- CSM 1.5.1

## Configuration 

### IMS Builder Image

In order for a compute node to be able to execute remote IMS builds, they must first be configured. After logging into a management node in your system,
retrieve the image id of the metal compute node shipped with CSM 1.5.1.

```
ncn-m001:~ # cray ims images list | grep -B 5 compute-csm.*aarch64
[[results]]
arch = "aarch64"
created = "2024-01-10T22:48:48.277640+00:00"
id = "f9de6a5b-b49d-4e7a-b78f-18599a8e61f9"
name = "compute-csm-1.5-5.2.47-aarch64"
```

Store that id and create a cfs configuration resembling the following. 

```
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
After posting your cfs configuration you will use it to customize the image id retrieved in the previous step.

```
cray cfs sessions create --target-group Application <IMS ID of your image> --target-image-map <IMS ID of your image> <name you want your new image to have in IMS> --target-definition image --name <pick a name for your CFS session> --configuration-name <name of the CFS configuration you created in the previous step>
```

Once the cfs customization is finished, the image is ready to be booted. Create a bos session template referencing that image and use it to boot an arm node.

```
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
Once the image is booted and operational you may also possibly look into the possiblity of adding an HSM lock to that node. This will prevent unwanted or accidental reboots or poweroffs.

```
cray hsm locks lock create --component-ids <compute node XNAME>
```

The lock can be removed at anytime via
```
cray hsm locks unlock create --component-ids <compute node XNAME>
```

### Storage 

By default compute nodes have limited storage. While executing small image builds may be possible, you will not be able to build larger images without additonal
storage being available to the ims builder node. We can achieve this by mounting ceph storage into the ims builder node.

Below are a set of commands that should provide the ims builder node with the storage that it needs to execute larger image builds 

From within IMS remote builder 
```
nid001030:~ # egrep 'NETCONFIG_DNS_STATIC_SERVERS|NETCONFIG_DNS_STATIC_SEARCHLIST' /etc/sysconfig/network/config
NETCONFIG_DNS_STATIC_SEARCHLIST="search nmn mtl hmn"
NETCONFIG_DNS_STATIC_SERVERS="10.92.100.225"

nid001030:~ # netconfig update -f
nid001030:~ # zypper install -y ceph-common
```

From within management node
```
ncn-m001:~ # scp /etc/ceph/ceph.conf <compute node XNAME>:/etc/ceph/ceph.conf
ncn-m001:~ # scp /etc/ceph/ceph.client.admin.keyring <compute node XNAME>:/etc/ceph/
```

From within IMS remote builder
```
nid001030:~ # RBD=$( rbd map kube/buildcache --id kube --keyring /etc/ceph/ceph.client.kube.keyring )
nid001030:~ # echo $RBD
/dev/rbd1

nid001030:~ # mkdir -p /mnt/cache
nid001030:~ # mount /dev/rbd1 /mnt/cache

nid001030:~ # mkdir /mnt/cache/tmp
nid001030:~ # mount --bind /mnt/cache/tmp /tmp
nid001030:~ # mkdir -p /mnt/cache//var/lib/containers/storage/overlay/
nid001030:~ # mount --bind /mnt/cache/var/lib/containers/storage/overlay/ /var/lib/containers/storage/overlay/
```

### Adding and Removing Remote Build Nodes to IMS 

Once your node has been configured with all of the above steps, the final step is to register that node with IMS so that it knows that it can be used for image builds.

Register a remote build node for ims
```
cray ims remote-build-nodes create --xname <compute node xname>
```
Removing a remote build node from ims 
```
cray ims remote-build-nodes delete <compute node xname>
```
List available remote build nodes 
```
cray ims remote-build-nodes list
```

Once complete you are all set to go. IMS will automatically use a remote build node for arm builds if one is made available so there will be no change to
previous commands for either create or customize jobs.




