
## Customize End-User UAI Images

The provided end-user UAI image is a basic UAI image that includes an up-to-date version of the Sles Linux Distribution and client support for both the Slurm and PBS Professional workload managers. It provides an entrypoint to using UAIs and doing workload management from UAIs. This UAI image is not suitable for use with the Cray PE because it cannot be assured of being up-to-date with what is running on Shasta compute nodes at a given site. To support building software to be run in compute nodes, it is necessary to create a custom end-user UAI image and use that.

A custom end-user UAI image can be any container image set up with the end-user UAI entrypoint script. For this case, it will be a UAI image built from the squashfs image used on compute nodes on the host system. This section describes how to create this kind of custom end-user UAI image.

### Prerequisites

-   This procedure requires administrator privileges.
-   All steps in this procedure must be run from a true NCN (master or worker node), not from the LiveCD node. In particular, pushing the final image to `registry.local` will fail with an error reporting a bad x509 certificate if it is attempted on the LiveCD node.

### Procedure

1. Build a custom end-user UAI image.

    The following steps are used to build a custom End-User UAI image called `registry.local/cray/cray-uai-compute:latest`. Alter this name as needed by changing the following in the procedure to use a different name:

    ```
    ncn-w001# UAI_IMAGE_NAME=registry.local/cray/cray-uai-compute:latest
    ```

1. Query BOS for a sessiontemplate ID.
    
    Identify the Sessiontemplate name to use. A full list may be found with the following command:

    ```
    ncn-w001# cray bos sessiontemplate list --format yaml
    - boot_sets:
        compute:
        boot_ordinal: 2
        etag: d54782b3853a2d8713a597d80286b93e
        kernel_parameters: console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g
            intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless
            numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y
            rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}
        network: nmn
        node_roles_groups:
        - Compute
        path: s3://boot-images/0c0d4081-2e8b-433f-b6f7-e1ef0b907be3/manifest.json
        rootfs_provider: cpss3
        rootfs_provider_passthrough: dvs:api-gw-service-nmn.local:300:nmn0
        type: s3
    cfs:
        configuration: wlm-config-0.1.0
    enable_cfs: true
    name: wlm-sessiontemplate-0.1.0
    ```

    Alternatively, collect the sessiontemplate name used when performing the installation/configuration procedure in the Cray Operating System (COS) documentation repository. Near the end of that procedure, the step to create a BOS session to boot the compute nodes should contain the name. 

    ```
    ncn-w001# SESSION_NAME=wlm-sessiontemplate-0.1.0
    ```

1. Download a compute node SquashFS.

    Use the Sessiontemplate name to download a compute node squashfs from a BOS sessiontemplate name:

    ```
    ncn-w001# SESSION_ID=$(cray bos sessiontemplate describe $SESSION_NAME --format json | jq -r '.boot_sets.compute.path' | awk -F/ '{print $4}')

    ncn-w001# cray artifacts get boot-images $SESSION_ID/rootfs rootfs.squashfs
    ```

1. Mount the SquashFS and create a tarball. 

    1. Create a directory to mount the SquashFS:

        ```
        ncn-w001# mkdir -v mount

        ncn-w001# mount -v -o loop,ro rootfs.squashfs `pwd`/mount
        ```

    1. Create the tarball.

        **IMPORTANT:** 99-slingshot-network.conf is omitted from the tarball as that prevents the UAI from running sshd as the UAI user with the `su` command:

        ```
        ncn-w001# (cd `pwd`/mount; tar --xattrs --xattrs-include='*' --exclude="99-slingshot-network.conf" -cf "../$SESSION_ID.tar" .) > /dev/null
        ```

        This may take several minutes. Notice that this does not create a compressed tarball. Using an uncompressed format makes it possible to add files if needed once the tarball is made. It also makes the procedure run just a bit more quickly. If warnings related to xattr are displayed, continue with the procedure as the resulting tarball should still result in a functing UAI container image. 
    
    1. Check that the tarball contains './usr/bin/uai-ssh.sh'.

        ```
        ncn-w001# tar tf $SESSION_ID.tar | grep '[.]/usr/bin/uai-ssh[.]sh'
        ./usr/bin/uai-ssh.sh
        ```

        If the script is not present, the easiest place to get a copy of the script is from a UAI built from the end-user UAI image provided with UAS, and it can be appended to the tarball:

        ```
        ncn-w001# mkdir -pv ./usr/bin
        ncn-w001# cray uas create --publickey ~/.ssh/id_rsa.pub
        uai_connect_string = "ssh vers@10.26.23.123"
        uai_host = "ncn-w001"
        uai_img = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
        uai_ip = "10.26.23.123"
        uai_msg = ""
        uai_name = "uai-vers-32079250"
        uai_status = "Pending"
        username = "vers"

        [uai_portmap]

        ncn-w001# scp vers@10.26.23.123:/usr/bin/uai-ssh.sh ./usr/bin/uai-ssh.sh
        The authenticity of host '10.26.23.123 (10.26.23.123)' can't be established.
        ECDSA key fingerprint is SHA256:voQUCKDG4C9FGkmUcHZVrYJBXVKVYqcJ4kmTpe4tvOA.
        Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
        Warning: Permanently added '10.26.23.123' (ECDSA) to the list of known hosts.
        uai-ssh.sh                                                                    100% 5035     3.0MB/s   00:00

        ncn-w001# cray uas delete --uai-list uai-vers-32079250
        results = [ "Successfully deleted uai-vers-32079250",]

        ncn-w001# tar rvf 0c0d4081-2e8b-433f-b6f7-e1ef0b907be3.tar ./usr/bin/uai-ssh.sh
        ```

1. Create and push the container image. 

    Create a container image using podman or docker and push it to the site container registry. Any container-specific modifications may also be done here with a Dockerfile. The ENTRYPOINT layer must be /usr/bin/uai-ssh.sh as that starts SSHD for the user in the UAI container started by UAS.

    ```
    ncn-w001# UAI_IMAGE_NAME=registry.local/cray/cray-uai-compute:latest

    ncn-w001# podman import --change "ENTRYPOINT /usr/bin/uai-ssh.sh" $SESSION_ID.tar $UAI_IMAGE_NAME

    ncn-w001# podman push $UAI_IMAGE_NAME
    ```

1. Register the new container image with UAS.

    ```
    ncn-w001# cray uas admin config images create --imagename $UAI_IMAGE_NAME
    ```

1. Cleanup the mount directory and tarball. 

    ```
    ncn-w001# umount -v mount; rmdir -v mount

    ncn-w001# rm $SESSION_ID.tar rootfs.squashfs

    # NOTE: the next step could be done as an `rm -rf` but, because the user
    #       is `root` and the path is very similar to an important system
    #       path a more cautious approach is taken.
    ncn-w001# rm -fv ./usr/bin/uai-ssh.sh && rmdir ./usr/bin ./usr
    ```

    
