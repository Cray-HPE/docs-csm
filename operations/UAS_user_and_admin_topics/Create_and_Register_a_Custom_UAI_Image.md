---
category: numbered
---

# Create and Register a Custom UAI Image

Use the compute node image to build a custom UAI image so that users can build compute node software using the HPE Cray PE.

-   This procedure requires administrator privileges.

-   Log into either a master or worker NCN node \(not a LiveCD node\).


-   **ROLE**

    System Administrator

-   **OBJECTIVE**

    Create a custom UAI image based on the current compute node image. This UAI image can then be used to build compute node software with Cray PE.

-   **NEW IN THIS RELEASE**

    This procedure is new in this release.


The default end-user UAI is not suitable for use with the Cray PE. The generic image cannot be guaranteed to be compatible with the software running on HPE Cray EX compute nodes at every customer site. Therefore, in order for users to build software for running on compute nodes, site administrators must create a custom end-user UAI for those users.

1.  Query the Boot Orchestration Service \(BOS\) for a compute node session template name to use.

    The following command returns a list of all registered BOS session templates in YAML format. Only a sample is shown in the example.

    In the following example, the compute node BOS session template name is wlm-sessiontemplate-0.1.0.

    ```screen
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

2.  Download the compute node squashfs image specified by the BOS session template.

    ```screen
    ncn# SESSION\_ID=$\(cray bos v1 sessiontemplate describe $SESSION\_NAME \\
    --format json \| jq -r '.boot\_sets.compute.path' \| awk -F/ '\{print $4\}'\)
    ncn# cray artifacts get boot-images $SESSION\_ID/rootfs rootfs.squashfs
    ```

3.  Create a directory to mount the downloaded squashfs.

    ```screen
    ncn# mkdir mount
    ncn# mount -o loop,rdonly rootfs.squashfs \`pwd\`/mount
    ```

4.  Create a tarball of the squashfs file system.

    The file 99-slingshot-network.conf must be omitted from the tarball as that prevents the UAI from running `sshd` as the UAI user with the su command.

    ```screen
    ncn# \(cd \`pwd\`/mount; tar --xattrs --xattrs-include='\*' \\
    --exclude="99-slingshot-network.conf" -cf "../$SESSION\_ID.tar" .\) \\
    \> /dev/null
    ```

    This command may take several minutes to complete. This command creates an uncompressed tar archive so that files can be added after the tarball is made. Using an uncompressed tarball also shortens the time required to complete this procedure.

5.  Wait for the previous command to complete. Then verify that the tarball contains the script /usr/bin/uai-ssh.sh from the squashfs.

    ```screen
    ncn# tar tf $SESSION\_ID.tar \| grep '\[.\]/usr/bin/uai-ssh\[.\]sh'
    ./usr/bin/uai-ssh.sh
    ```

6.  **Optional:**Obtain the /usr/bin/uai-ssh.sh script for a UAI built from the end-user UAI image provided with UAS. Then append it to the tarball. Skip this step if the script was detected within the tarball.

    ```screen
    ncn# mkdir -p ./usr/bin
    ncn# cray uas create --publickey ~/.ssh/id\_rsa.pub
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

7.  Create a container image using podman or docker and push it to the site container registry. Perform any container-specific modifications, if wanted, with a dockerfile before pushing the container image.

    The `ENTRYPOINT` layer must be /usr/bin/uai-ssh.sh as that starts `sshd` for the user in the UAI container started by UAS.

    The following example assumes that the custom end-user UAI image will be called `registry.local/cray/cray-uai-compute:latest`. Use a different name if wanted.

    ```screen
    ncn# UAI\_IMAGE\_NAME=registry.local/cray/cray-uai-compute:latest
    ncn# podman import --change "ENTRYPOINT /usr/bin/uai-ssh.sh" \\
    $SESSION\_ID.tar $UAI\_IMAGE\_NAME
    ncn# podman push $UAI\_IMAGE\_NAME
    ```

8.  Register the new container image with UAS.

    ```screen
    ncn# cray uas admin config images create --imagename $UAI\_IMAGE\_NAME
    ```

9.  Delete the squashfs mount directory and tarball.

    Since the commands in the following example are executed by the root user and these temporary directories are similar to an important system path, the second rm command does not use the common -r as a precaution.

    ```screen
    ncn# umount mount; rmdir mount
    ncn# rm $SESSION\_ID.tar rootfs.squashfs
    ncn# rm -f ./usr/bin/uai-ssh.sh && rmdir ./usr/bin ./usr
    ```


-   **[Add a Volume to UAS](Add_a_Volume_to_UAS.md)**  
How to add a volume to UAS. Adding a volume registers it with UAS and makes it available to UAIs.
-   **[Delete a Volume Configuration](Delete_a_Volume_Configuration.md)**  
How to delete a volume configuration and prevent its being mounted in UAIs.
-   **[Reset the UAS Configuration to Original Installed Settings](Reset_the_UAS_Configuration_to_Original_Installed_Settings.md)**  
How to remove a customized UAS configuration and restore the base installed configuration.

**Parent topic:**[User Access Service \(UAS\)](User_Access_Service_UAS.md)

