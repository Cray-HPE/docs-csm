# Customize End-User UAI Images

The provided End-User UAI image is a basic UAI image that includes an up-to-date version of the SLES Linux Distribution. It provides an entry point to using UAIs and an easy way for administrators to experiment with UAS configurations.
To support building software to be run in compute nodes, or other HPC and Analytics workflows, it is necessary to create a custom End-User UAI image and use that.

A custom End-User UAI image can be any container image set up with the End-User UAI `entrypoint.sh` script.
Experimentation with the wide range of possible UAI images is beyond the scope of this document, but the example given here should offer a starting point for that kind of experimentation.

The example provided here covers the most common use-case, which is building a UAI image from the SquashFS image used on compute nodes on the host system to support application development, workload management and analytics workflows.
Some of the steps are specific to that activity, others would be common to or similar to steps needed to create special purpose UAIs.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)

**NOTE:** This procedure cannot be run from a PIT node or an external host, it must be run from a Kubernetes Worker or Master node.

## Procedure

1. Choose a name for the custom image

     This example names the custom End-User UAI image called `registry.local/cray/cray-uai-compute:latest`, and places that name in an environment variable for convenience. Alter the name as appropriate for the image to be created:

    ```bash
    ncn-w001# UAI_IMAGE_NAME=registry.local/cray/cray-uai-compute:latest
    ```

2. Query BOS for a `sessiontemplate` ID.

    Identify the `sessiontemplate` name to use. A full list may be found with the following command:

    ```bash
    ncn-w001# cray bos sessiontemplate list --format yaml
    ```

    Example output:

    ```bash
    - boot_sets:
        compute:
        boot_ordinal: 2
        etag: d54782b3853a2d8713a597d80286b93e
        kernel_parameters: ip=dhcp quiet spire_join_token=${SPIRE_JOIN_TOKEN}
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

    Alternatively, collect the sessiontemplate name used during the Cray Operating System (COS) install. Refer to the "Boot COS" procedure in the COS product stream documentation.
    Near the end of that procedure, the step to create a BOS session to boot the compute nodes should contain the name.

    ```bash
    ncn-w001# SESSION_NAME=wlm-sessiontemplate-0.1.0
    ```

3. Download a compute node SquashFS.

    Use the `sessiontemplate` name to download a compute node SquashFS from a BOS `sessiontemplate` name:

    ```bash
    ncn-w001# SESSION_ID=$(cray bos sessiontemplate describe $SESSION_NAME --format json | jq -r '.boot_sets.compute.path' | awk -F/ '{print $4}')

    ncn-w001# cray artifacts get boot-images $SESSION_ID/rootfs rootfs.squashfs
    ```

4. Mount the SquashFS and create a tarball.

    1. Create a directory and mount the SquashFS on the directory:

        ```bash
        ncn-w001# mkdir -v mount

        ncn-w001# mount -v -o loop,ro rootfs.squashfs `pwd`/mount
        ```

    2. Create the tarball.

        **IMPORTANT:** 99-slingshot-network.conf is omitted from the tarball as that prevents the UAI from running SSHD as the UAI user with the `su` command:

        ```bash
        ncn-w001# (cd `pwd`/mount; tar --xattrs --xattrs-include='*' --exclude="99-slingshot-network.conf" -cf "../$SESSION_ID.tar" .) > /dev/null
        ```

        This may take several minutes. Notice that this does not create a compressed tarball. Using an uncompressed format makes it possible to add files if needed once the tarball is made.
        It also makes the procedure run just a bit more quickly. If warnings related to xattr are displayed, continue with the procedure as the resulting tarball should still result in a functioning UAI container image.

    3. Check that the tarball contains `./usr/bin/uai-ssh.sh`.

        ```bash
        ncn-w001# tar tf $SESSION_ID.tar | grep '[.]/usr/bin/uai-ssh[.]sh'
        ./usr/bin/uai-ssh.sh
        ```

        If this script is not present, the easiest place to get a copy of the script is from a UAI built from the End-User UAI image provided with UAS, and it can be appended to the tarball:

        ```bash
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

5. Create and push the container image.

    Create a container image using podman or docker and push it to the site container registry. Any container-specific modifications may also be done here with a Dockerfile.
    The `ENTRYPOINT` layer must be `/usr/bin/uai-ssh.sh` as that starts SSHD for the user in the UAI container started by UAS.

    ```bash
    ncn-w001# UAI_IMAGE_NAME=registry.local/cray/cray-uai-compute:latest

    ncn-w001# podman import --change "ENTRYPOINT /usr/bin/uai-ssh.sh" $SESSION_ID.tar $UAI_IMAGE_NAME

    ncn-w001# podman push $UAI_IMAGE_NAME
    ```

6. Register the new container image with UAS.

    ```bash
    ncn-w001# cray uas admin config images create --imagename $UAI_IMAGE_NAME
    ```

7. Cleanup the mount directory and tarball.

    ```bash
    ncn-w001# umount -v mount; rmdir -v mount

    ncn-w001# rm $SESSION_ID.tar rootfs.squashfs

    # NOTE: The next step could be done as an `rm -rf` but, because the user
    #       is `root` and the path is very similar to an important system
    #       path a more cautious approach is taken.

    ncn-w001# rm -fv ./usr/bin/uai-ssh.sh && rmdir ./usr/bin ./usr
    ```

[Top: User Access Service (UAS)](index.md)

[Next Topic: Legacy Mode User-Driven UAI Management](Legacy_Mode_User-Driven_UAI_Management.md)
