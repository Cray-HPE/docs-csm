# Customize End-User UAI Images

The provided end-user UAI image is a basic UAI image that includes an up-to-date version of the SLES Linux distribution. It provides an entry point to using UAIs and an easy way for administrators to experiment with UAS configurations.
To support building software to be run in compute nodes, or other HPC and Analytics workflows, it is necessary to create a custom end-user UAI image and use that.

A custom end-user UAI image can be any container image set up with the end-user UAI `entrypoint.sh` script.
Experimentation with the wide range of possible UAI images is beyond the scope of this document, but the example given here should offer a starting point for that kind of experimentation.

The example provided here covers the most common use-case, which is building a UAI image from the SquashFS image used on compute nodes on the host system to support application development, workload management and analytics workflows.
Some of the steps are specific to that activity, others would be common to or similar to steps needed to create special purpose UAIs.

## Prerequisites

* The administrator must be logged into a [Non-Compute Node (NCN)](../../glossary.md#non-compute-node-ncn) or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the [HPE Cray EX System CLI](../../glossary.md#cray-cli-cray) (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)

See [Configure the Cray CLI](../configure_cray_cli.md).

**NOTE:** This procedure cannot be run from a PIT node or an external host, it must be run from a Kubernetes worker or master node.

## Procedure

1. Choose a name for the custom image.

     This example names the custom end-user UAI image called `registry.local/cray/cray-uai-compute:latest`, and places that name in an environment variable for convenience. Alter the name as appropriate for the image to be created:

    ```bash
    ncn-mw# UAI_IMAGE_NAME=registry.local/cray/cray-uai-compute:latest
    ```

1. Query the [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos) for a session template ID.

    Identify the session template name to use. A full list may be found with the following command:

    ```bash
    ncn-mw# cray bos sessiontemplate list --format yaml
    ```

    Example output:

    ```yaml
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

    Alternatively, collect the session template name used during the [Cray Operating System (COS)](../../glossary.md#cray-operating-system-cos) install.
    Refer to the "Boot COS" procedure in the COS product stream documentation.
    Near the end of that procedure, the step to create a BOS session to boot the compute nodes should contain the name.

1. Record the session template name.

    ```bash
    ncn-mw# ST_NAME=wlm-sessiontemplate-0.1.0
    ```

1. Download a compute node SquashFS.

    Use the session template name to download a compute node SquashFS from a BOS session template name:

    ```bash
    ncn-mw# ST_ID=$(cray bos sessiontemplate describe $ST_NAME --format json | jq -r '.boot_sets.compute.path' | awk -F/ '{print $4}')

    ncn-mw# cray artifacts get boot-images $ST_ID/rootfs rootfs.squashfs
    ```

1. Mount the SquashFS and create a tarball.

    1. Create a directory and mount the SquashFS on the directory.

        ```bash
        ncn-w001# mkdir -v mount

        ncn-mw# mount -v -o loop,ro rootfs.squashfs `pwd`/mount
        ```

    1. Create the tarball.

        **IMPORTANT:** `99-slingshot-network.conf` is omitted from the tarball, because that prevents the UAI from running `sshd` as the UAI user with the `su` command.

        ```bash
        ncn-mw# (cd `pwd`/mount; tar --xattrs --xattrs-include='*' --exclude="99-slingshot-network.conf" -cf "../$ST_ID.tar" .) 2> /dev/null
        ```

        This may take several minutes. Notice that this does not create a compressed tarball. Using an uncompressed format makes it possible to add files if needed once the tarball is made.
        It also makes the procedure run slightly faster. Warnings related to `xattr` can be ignored; the resulting tarball should still result in a functioning UAI container image.

    1. Check that the tarball contains `./usr/bin/uai-ssh.sh`.

        ```bash
        ncn-mw# tar tf $ST_ID.tar | grep '[.]/usr/bin/uai-ssh[.]sh'
        ```

        Example output:

        ```text
        ./usr/bin/uai-ssh.sh
        ```

        If this script is not present, the easiest place to get a copy of the script is from a UAI built from the end-user UAI image provided with UAS.
        After getting a copy of the script, it can be appended to the tarball.

        1. Create a directory for the script.

            ```bash
            ncn-mw# mkdir -pv ./usr/bin
            ```

        1. Create a UAI.

            ```bash
            ncn-mw# cray uas create --format toml --publickey ~/.ssh/id_rsa.pub
            ```

            Example output:

            ```toml
            uai_connect_string = "ssh vers@10.26.23.123"
            uai_host = "ncn-w001"
            uai_img = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
            uai_ip = "10.26.23.123"
            uai_msg = ""
            uai_name = "uai-vers-32079250"
            uai_status = "Pending"
            username = "vers"

            [uai_portmap]
            ```

        1. Copy the script from the UAI.

            ```bash
            ncn-mw# scp vers@10.26.23.123:/usr/bin/uai-ssh.sh ./usr/bin/uai-ssh.sh
            ```

            Example output:

            ```text
            The authenticity of host '10.26.23.123 (10.26.23.123)' can't be established.
            ECDSA key fingerprint is SHA256:voQUCKDG4C9FGkmUcHZVrYJBXVKVYqcJ4kmTpe4tvOA.
            Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
            Warning: Permanently added '10.26.23.123' (ECDSA) to the list of known hosts.
            uai-ssh.sh                                                                    100% 5035     3.0MB/s   00:00
            ```

        1. Delete the UAI.

            ```bash
            ncn-mw# cray uas delete --uai-list uai-vers-32079250 --format toml
            ```

            Example output:

            ```toml
            results = [ "Successfully deleted uai-vers-32079250",]
            ```

        1. Append the script to the tarball.

            ```bash
            ncn-mw# tar rvf 0c0d4081-2e8b-433f-b6f7-e1ef0b907be3.tar ./usr/bin/uai-ssh.sh
            ```

1. Create and push the container image.

    Create a container image using Podman or Docker and push it to the site container registry. Any container-specific modifications may also be done here with a Dockerfile.
    The `ENTRYPOINT` layer must be `/usr/bin/uai-ssh.sh` as that starts `sshd` for the user in the UAI container started by UAS.

    ```bash
    ncn-mw# UAI_IMAGE_NAME=registry.local/cray/cray-uai-compute:latest

    ncn-mw# podman import --change "ENTRYPOINT /usr/bin/uai-ssh.sh" $ST_ID.tar $UAI_IMAGE_NAME

    ncn-mw# PODMAN_USER=$(kubectl get secret -n nexus nexus-admin-credential -o json | jq -r '.data.username' | base64 -d)

    ncn-mw# PODMAN_PASSWD=$(kubectl get secret -n nexus nexus-admin-credential -o json | jq -r '.data.password' | base64 -d)

    ncn-mw# podman push --creds "$PODMAN_USER:$PODMAN_PASSWD" $UAI_IMAGE_NAME
    ```

1. Register the new container image with UAS.

    ```bash
    ncn-mw# cray uas admin config images create --imagename $UAI_IMAGE_NAME
    ```

1. Cleanup the mount directory and tarball.

    ```bash
    ncn-mw# umount -v mount; rmdir -v mount

    ncn-mw# rm -v $ST_ID.tar rootfs.squashfs

    # NOTE: The next step could be done as an `rm -rf` but, because the user
    #       is `root` and the path is very similar to an important system
    #       path a more cautious approach is taken.

    ncn-mw# rm -fv ./usr/bin/uai-ssh.sh && rmdir ./usr/bin ./usr
    ```
