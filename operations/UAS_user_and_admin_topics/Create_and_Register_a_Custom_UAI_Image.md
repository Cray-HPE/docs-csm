
## Create and Register a Custom UAI Image

Create a custom UAI image based on the current compute node image. This UAI image can then be used to build compute node software with the Cray Programming Environment (PE).

### Prerequisites

-   This procedure requires administrator privileges.
-   Log into either a master or worker NCN node \(not a LiveCD node\).

### Procedure

The default end-user UAI is not suitable for use with the Cray PE. The generic image cannot be guaranteed to be compatible with the software running on HPE Cray EX compute nodes at every customer site. Therefore, in order for users to build software for running on compute nodes, site administrators must create a custom end-user UAI for those users.

1.  Query the Boot Orchestration Service \(BOS\) for a compute node session template name to use.

    The following command returns a list of all registered BOS session templates in YAML format. Only a sample is shown in the example.

    In the following example, the compute node BOS session template name is wlm-sessiontemplate-0.1.0.

    ```bash
    ncn# cray bos sessiontemplate list --format yaml
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

2.  Download the compute node SquashFS image specified by the BOS session template.

    ```bash
    ncn# SESSION_ID=$(cray bos v1 sessiontemplate describe $SESSION_NAME \
    --format json | jq -r '.boot_sets.compute.path' | awk -F/ '{print $4}')
    ncn# cray artifacts get boot-images $SESSION_ID/rootfs rootfs.squashfs
    ```

3.  Create a directory to mount the downloaded SquashFS.

    ```bash
    ncn# mkdir mount
    ncn# mount -o loop,ro rootfs.squashfs \`pwd\`/mount
    ```

4.  Create a tarball of the SquashFS file system.

    The file 99-slingshot-network.conf must be omitted from the tarball as that prevents the UAI from running `sshd` as the UAI user with the su command.

    ```bash
    ncn# (cd `pwd`/mount; tar --xattrs --xattrs-include='*' \
    --exclude="99-slingshot-network.conf" -cf "../$SESSION_ID.tar" .) \
    > /dev/null
    ```

    This command may take several minutes to complete. This command creates an uncompressed tar archive so that files can be added after the tarball is made. Using an uncompressed tarball also shortens the time required to complete this procedure.

5.  Wait for the previous command to complete. Then verify that the tarball contains the script /usr/bin/uai-ssh.sh from the SquashFS.

    ```bash
    ncn# tar tf $SESSION_ID.tar | grep '[.]/usr/bin/uai-ssh[.]sh'
    ./usr/bin/uai-ssh.sh
    ```

6.  **Optional:** Obtain the /usr/bin/uai-ssh.sh script for a UAI built from the end-user UAI image provided with UAS. Then append it to the tarball. Skip this step if the script was detected within the tarball.

    ```bash
    ncn# mkdir -p ./usr/bin
    ncn# cray uas create --publickey ~/.ssh/id_rsa.pub
    uai_connect_string = "ssh vers@10.26.23.123"
    uai_host = "ncn-w001"
    uai_img = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
    uai_ip = "10.26.23.123"
    uai_msg = ""
    uai_name = "uai-vers-32079250"
    uai_status = "Pending"
    username = "vers"

    [uai_portmap]

    ncn# scp vers@10.26.23.123:/usr/bin/uai-ssh.sh ./usr/bin/uai-ssh.sh
    The authenticity of host '10.26.23.123 (10.26.23.123)' can't be established.
    ECDSA key fingerprint is SHA256:voQUCKDG4C9FGkmUcHZVrYJBXVKVYqcJ4kmTpe4tvOA.
    Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
    Warning: Permanently added '10.26.23.123' (ECDSA) to the list of known hosts.
    uai-ssh.sh                                                                    100% 5035     3.0MB/s   00:00
    ncn# cray uas delete --uai-list uai-vers-32079250
    results = [ "Successfully deleted uai-vers-32079250",]
    ncn# tar rf 0c0d4081-2e8b-433f-b6f7-e1ef0b907be3.tar ./usr/bin/uai-ssh.sh
    ```

7.  Create a container image using `podman` or `docker` and push it to the site container registry. Perform any container-specific modifications, if wanted, with a dockerfile before pushing the container image.

    The `ENTRYPOINT` layer must be /usr/bin/uai-ssh.sh as that starts `sshd` for the user in the UAI container started by UAS.

    The following example assumes that the custom end-user UAI image will be called `registry.local/cray/cray-uai-compute:latest`. Use a different name if wanted.

    ```bash
    ncn# UAI_IMAGE_NAME=registry.local/cray/cray-uai-compute:latest
    ncn# podman import --change "ENTRYPOINT /usr/bin/uai-ssh.sh" \
    $SESSION_ID.tar $UAI_IMAGE_NAME
    ncn# podman push $UAI_IMAGE_NAME
    ```

8.  Register the new container image with UAS.

    ```bash
    ncn# cray uas admin config images create --imagename $UAI_IMAGE_NAME
    ```

9.  Delete the SquashFS mount directory and tarball.

    Because the commands in the following example are executed by the root user and these temporary directories are similar to an important system path, the second `rm` command does not use the common `-r` as a precaution.

    ```bash
    ncn# umount mount; rmdir mount
    ncn# rm $SESSION_ID.tar rootfs.squashfs
    ncn# if [ -f ./usr/bin/uai-ssh.sh ]; then rm -f ./usr/bin/uai-ssh.sh && rmdir ./usr/bin ./usr; fi
    ```


