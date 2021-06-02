## Create UAN Boot Images

Update configuration management git repository to match the installed version of the UAN product. Then use that updated configuration to create UAN boot images and a BOS session template.

This is the overall workflow for preparing UAN images for booting UANs:

1.  Clone the UAN configuration git repository and create a branch based on the branch imported by the UAN installation.
2.  Update the configuration content and push the changes to the newly created branch.
3.  Create a Configuration Framework Service \(CFS\) configuration for the UANs, specifying the git configuration and the UAN image to apply the configuration to. More Cray products can also be added to the CFS configuration so that the UANs can install multiple Cray products into the UAN image at the same time.
4.  Configure the UAN image using CFS and generate a newly configured version of the UAN image.
5.  Create a Boot Orchestration Service \(BOS\) boot session template for the UANs. This template maps the configured image, the CFS configuration to be applied post-boot, and the nodes which will receive the image and configuration.

Once the UAN BOS session template is created, the UANs will be ready to be booted by a BOS session.

Replace PRODUCT\_VERSION and CRAY\_EX\_HOSTNAME in the example commands in this procedure with the current UAN product version installed \(See Step 1\) and the hostname of the HPE Cray EX system, respectively.

### Prerequisites

The UAN product stream must be installed.

### Limitations

This guide only details how to apply UAN-specific configuration to the UAN image and nodes. Consult the manuals for the individual HPE products \(for example, workload managers and the HPE Cray Programming Environment\) that must be configured on the UANs.


### UAN Image Pre-Boot Configuration

1.  Obtain the artifact IDs and other information from the `cray-product-catalog` Kubernetes ConfigMap. Record the information labeled in the following example.

    Upon successful installation of the UAN product, the UAN configuration, image recipes, and prebuilt boot images are cataloged in this ConfigMap. This information is required for this procedure.

    ```bash
    ncn-m001# kubectl get cm -n services cray-product-catalog -o json | jq -r .data.uan
    PRODUCT_VERSION:
      configuration:
        clone_url: https://vcs.CRAY_EX_HOSTNAME/vcs/cray/uan-config-management.git # <--- Gitea clone url
        commit: 6658ea9e75f5f0f73f78941202664e9631a63726                   # <--- Git commit id
        import_branch: cray/uan/PRODUCT_VERSION                           # <--- Git branch with configuration
        import_date: 2021-02-02 19:14:18.399670
        ssh_url: git@vcs.CRAY_EX_HOSTNAME:cray/uan-config-management.git
      images:
        cray-shasta-uan-cos-sles15sp1.x86_64-0.1.17:                       # <--- IMS image name
          id: c880251d-b275-463f-8279-e6033f61578b                         # <--- IMS image id
      recipes:
        cray-shasta-uan-cos-sles15sp1.x86_64-0.1.17:                       # <--- IMS recipe name
          id: cbd5cdf6-eac3-47e6-ace4-aa1aecb1359a                         # <--- IMS recipe id
    ```

2.  Generate the password hash for the `root` user. Replace PASSWORD with the `root` password you wish to use.

    ```bash
    ncn-m001# openssl passwd -6 -salt $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c4) PASSWORD
    ```

3.  Obtain the HashiCorp Vault `root` token.

    ```bash
    ncn-m001# kubectl get secrets -n vault cray-vault-unseal-keys -o jsonpath='{.data.vault-root}' \
    | base64 -d; echo
    ```

4.  Write the password hash obtained in Step 2 to the HashiCorp Vault.

    The vault login command will request a token. That token value is the output of the previous step. The vault read secret/uan command verifies that the hash was stored correctly. This password hash will be written to the UAN for the `root` user by CFS.

    ```bash
    ncn-m001# kubectl exec -itn vault cray-vault-0 -- sh
    export VAULT_ADDR=http://cray-vault:8200
    vault login
    vault write secret/uan root_password='HASH'
    vault read secret/uan
    ```

5.  Obtain the password for the `crayvcs` user from the Kubernetes secret for use in the next command.

    ```bash
    ncn-m001# kubectl get secret -n services vcs-user-credentials \
    --template={{.data.vcs_password}} | base64 --decode
    ```

6.  Clone the UAN configuration management repository. Replace CRAY\_EX\_HOSTNAME in clone url with **api-gw-service-nmn.local** when cloning the repository.

    The repository is in the VCS/Gitea service and the location is reported in the cray-product-catalog Kubernetes ConfigMap in the `configuration.clone_url` key. The CRAY\_EX\_HOSTNAME from the `clone_url` is replaced with `api-gw-service-nmn.local` in the command that clones the repository.

    ```bash
    ncn-m001# git clone https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
    . . .
    ncn-m001# cd uan-config-management && git checkout cray/uan/PRODUCT_VERSION && git pull
    Branch 'cray/uan/PRODUCT_VERSION' set up to track remote branch 'cray/uan/PRODUCT_VERSION' from 'origin'.
    Already up to date.
    ```

7.  Create a branch using the imported branch from the installation to customize the UAN image.

    This imported branch will be reported in the cray-product-catalog Kubernetes ConfigMap in the `configuration.import_branch` key under the UAN section. The format is cray/uan/PRODUCT\_VERSION. In this guide, an `integration` branch is used for examples, but the name can be any valid git branch name.

    Modifying the cray/uan/PRODUCT\_VERSION branch that was created by the UAN product installation is not allowed by default.

    ```bash
    ncn-m001# git checkout -b integration && git merge cray/uan/PRODUCT_VERSION
    Switched to a new branch 'integration'
    Already up to date.
    ```

8.  Configure a root user in the UAN image by adding the encrypted password of the root user from /etc/shadow on an NCN worker to the file group\_vars/Application/passwd.yml. Skip this step if the root user is already configured in the image.

    Hewlett Packard Enterprise recommends configuring a root user in the UAN image for troubleshooting purposes. The entry for root user password will resemble the following example:

    ```bash
    root_passwd: $6$LmQ/PlWlKixK$VL4ueaZ8YoKOV6yYMA9iH0gCl8F4C/3yC.jMIGfOK6F61h6d.iZ6/QB0NLyex1J7AtOsYvqeycmLj2fQcLjfE1
    ```

9.  Apply any site-specific customizations and modifications to the Ansible configuration for the UAN nodes and commit the changes.

    The default Ansible play to configure UAN nodes is site.yml in the base of the uan-config-management repository. The roles that are executed in this play allow for nondefault configuration as required for the system.

    Consult the individual Ansible role README.md files in the uan-config-management repository roles directory to configure individual role variables. Roles prefixed with uan\_ are specific to UAN configuration and include network interfaces, disk, LDAP, software packages, and message of the day roles.

    Variables should be defined and overridden in the Ansible inventory locations of the repository as shown in the following example and **not** in the Ansible plays and roles defaults. See https://docs.ansible.com/ansible/2.9/user\_guide/playbooks\_best\_practices.html\#content-organization for directory layouts for inventory.

    **Warning:** Never place sensitive information such as passwords in the git repository.

    The following example shows how to add a vars.yml file containing site-specific configuration values to the `Application` group variable location.

    These and other Ansible files do not necessarily need to be modified for UAN image creation.

    ```bash
    ncn-m001# vim group_vars/Application/vars.yml
    ncn-m001# git add group_vars/Application/vars.yml
    ncn-m001# git commit -m "Add vars.yml customizations"
    [integration ecece54] Add vars.yml customizations
     1 file changed, 1 insertion(+)
     create mode 100644 group_vars/Application/vars.yml
    ```

10. Verify that the System Layout Service \(SLS\) and the uan\_interfaces configuration role refer to the Mountain Node Management Network by the same name. Skip this step if there are no Mountain cabinets in the HPE Cray EX system.

    1.  Edit the roles/uan\_interfaces/tasks/main.yml file and change the line that reads `url: http://cray-sls/v1/search/networks?name=MNMN` to read `url: http://cray-sls/v1/search/networks?name=NMN_MTN`.

        The following excerpt of the relevant section of the file shows the result of the change.

        ```bash
        - name: Get Mountain NMN Services Network info from SLS
          local_action:
            module: uri
              url: http://cray-sls/v1/search/networks?name=NMN_MTN 
            method: GET
          register: sls_mnmn_svcs
          ignore_errors: yes 
        ```

    2.  Stage and commit the network name change

        ```bash
        ncn-m# git add roles/uan_interfaces/tasks/main.yml
        ncn-m# git commit -m "Add Mountain cabinet support"
        ```

11. Push the changes to the repository using the proper credentials, including the password obtained previously.

    ```bash
    ncn-m001# git push --set-upstream origin integration
    Username for 'https://api-gw-service-nmn.local': crayvcs
     Password for 'https://crayvcs@api-gw-service-nmn.local':
     . . .
     remote: Processed 1 references in total
     To https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
      * [new branch]      integration -> integration
      Branch 'integration' set up to track remote branch 'integration' from 'origin'.
    ```

12. Capture the most recent commit for reference in setting up a CFS configuration and navigate to the parent directory.

    ```bash
    ncn-m001# git rev-parse --verify HEAD
    
    ecece54b1eb65d484444c4a5ca0b244b329f4667
    
    ncn-m001# cd ..
    ```

    The configuration parameters have been stored in a branch in the UAN git repository. The next phase of the process is initiating the Configuration Framework Service \(CFS\) to customize the image.

### Configure UAN Images

14. Create a JSON input file for generating a CFS configuration for the UAN.

    Gather the git repository clone URL, commit, and top-level play for each configuration layer \(that is, Cray product\). Add them to the CFS configuration for the UAN, if wanted.

    For the commit value for the UAN layer, use the Git commit value obtained in the previous step.

    See the product manuals for further information on configuring other Cray products, as this procedure documents only the configuration of the UAN. More layers can be added to be configured in a single CFS session.

    The following configuration example can be used for preboot image customization as well as post-boot node configuration.

    ```bash
    {
      "layers": [
        {
          "name": "uan-integration-PRODUCT\_VERSION",
          "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
          "playbook": "site.yml",
          "commit": "ecece54b1eb65d484444c4a5ca0b244b329f4667"
        }
        # **{ ... add configuration layers for other products here, if desired ... }**
      ]
    }
    ```

15. Add the configuration to CFS using the JSON input file.

    In the following example, the JSON file created in the previous step is named uan-config-PRODUCT\_VERSION.json only the details for the UAN layer are shown.

    ```bash
    ncn-m001# cray cfs configurations update uan-config-PRODUCT_VERSION \
                      --file ./uan-config-PRODUCT_VERSION.json \
                      --format json
    {
      "lastUpdated": "2021-07-28T03:26:00:37Z",
      "layers": [
        {
          "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
          "commit": "ecece54b1eb65d484444c4a5ca0b244b329f4667",
          "name": "uan-integration-PRODUCT_VERSION",
          "playbook": "site.yml"
        }  # <-- Additional layers not shown, but would be inserted here
      ],
      "name": "uan-config-PRODUCT_VERSION"
    }
    ```

16. Modify the UAN image to include the 1.4.0 day zero rpms .

    1.  Untar the 1.4.0 Day Zero Patch tarball if it is not untarred already.

        ```bash
        ncn-m001# tar -xvf shasta-1.4.0-p2.tar
        1.4.0-p2/
        1.4.0-p2/csm/
        1.4.0-p2/csm/csm-0.8.22-0.9.0.patch.gz
        1.4.0-p2/csm/csm-0.8.22-0.9.0.patch.gz.md5sum
        1.4.0-p2/uan/
        1.4.0-p2/uan/uan-2.0.0-uan-2.0.0.patch.gz
        1.4.0-p2/uan/uan-2.0.0-uan-2.0.0.patch.gz.md5sum
        1.4.0-p2/rpms/
        1.4.0-p2/rpms/cray-dvs-compute-2.12_4.0.102-7.0.1.0_8.1__g30d29e7a.x86_64.rpm
        1.4.0-p2/rpms/cray-dvs-devel-2.12_4.0.102-7.0.1.0_8.1__g30d29e7a.x86_64.rpm
        1.4.0-p2/rpms/cray-dvs-kmp-cray_shasta_c-2.12_4.0.102_k4.12.14_197.78_9.1.58-7.0.1.0_8.1__g30d29e7a.x86_64.rpm
        1.4.0-p2/rpms/cray-network-config-1.1.7-20210318094806_b409053-sles15sp1.x86_64.rpm
        1.4.0-p2/rpms/slingshot-network-config-1.1.7-20210318093253_83fab52-sles15sp1.x86_64.rpm
        1.4.0-p2/rpms/slingshot-network-config-full-1.1.7-20210318093253_83fab52-sles15sp1.x86_64.rpm
        1.4.0-p2/rpms/cray-dvs-compute-2.12_4.0.102-7.0.1.0_8.1__g30d29e7a.x86_64.rpm.md5sum
        1.4.0-p2/rpms/cray-dvs-devel-2.12_4.0.102-7.0.1.0_8.1__g30d29e7a.x86_64.rpm.md5sum
        1.4.0-p2/rpms/cray-dvs-kmp-cray_shasta_c-2.12_4.0.102_k4.12.14_197.78_9.1.58-7.0.1.0_8.1__g30d29e7a.x86_64.rpm.md5sum
        1.4.0-p2/rpms/cray-network-config-1.1.7-20210318094806_b409053-sles15sp1.x86_64.rpm.md5sum
        1.4.0-p2/rpms/slingshot-network-config-1.1.7-20210318093253_83fab52-sles15sp1.x86_64.rpm.md5sum
        1.4.0-p2/rpms/slingshot-network-config-full-1.1.7-20210318093253_83fab52-sles15sp1.x86_64.rpm.md5sum
        ```

    2.  Download the rootfs image specified in the UAN product catalog.

        Replace IMAGE\_ID in the following export command with the IMS image id recorded in Step 1.

        ```bash
        ncn-m001# export UAN_IMAGE_ID=IMAGE_ID
        ncn-m001# cray artifacts get boot-images ${UAN_IMAGE_ID}/rootfs \
        ${UAN_IMAGE_ID}.squashfs
        ncn-m001# la ${UAN_IMAGE_ID}.squashfs
        -rw-r--r-- 1 root root 1.5G Mar 17 19:35 f3ba09d7-e3c2-4b80-9d86-0ee2c48c2214.squashfs
        ```

    3.  Mount the squashfs file and copy its contents to a different directory.

        ```bash
        ncn-m001# mkdir mnt
        ncn-m001# mkdir UAN-1.4.0-day-zero
        ncn-m001# mount -t squashfs ${UAN_IMAGE_ID}.squashfs mnt -o ro,loop
        ncn-m001# cp -a mnt UAN-1.4.0-day-zero
        ncn-m001# umount mnt
        ncn-m001# rmdir mnt
        ```

    4.  Copy the new RPMs into the new image directory.

        ```bash
        ncn-m001# cp 1.4.0-p2/rpms/* UAN-1.4.0-day-zero/
        ncn-m001# cd UAN-1.4.0-day-zero/
        ```

    5.  Chroot into the new image directory.

        ```bash
        ncn-m001# chroot . bash
        ```

    6.  Update, erase, and install RPMs in the new image directory.

        ```bash
        chroot-ncn-m001# rpm -Uv cray-dvs-*.rpm
        chroot-ncn-m001# rpm -e cray-network-config
        chroot-ncn-m001# rpm -e slingshot-network-config-full
        chroot-ncn-m001# rpm -e slingshot-network-config
        chroot-ncn-m001# rpm -iv slingshot-network-config-full-1.1.7-20210318093253_83fab52-sles15sp1.x86_64.rpm \ 
        slingshot-network-config-1.1.7-20210318093253_83fab52-sles15sp1.x86_64.rpm \ 
        cray-network-config-1.1.7-20210318094806_b409053-sles15sp1.x86_64.rpm
        ```

    7.  Generate a new initrd to match the updated image by running the /tmp/images.sh script. Then wait for this script to complete before continuing.

        ```bash
        chroot-ncn-m001# /tmp/images.sh
        ```

        The output of this script will contain error messages. These error messages can be ignored as long as the message dracut: \*\*\* Creating initramfs image file appears at the end.

    8.  Copy the /boot/initrd and /boot/vmlinuz files out of the chroot environment and into a temporary location on the file system of the node.

    9.  Exit the chroot environment and delete the packages.

        ```bash
        chroot-ncn-m001# exit
        exit
        ncn-m001# rm *.rpm
        ncn-m001# cd ..
        ```

    10. Verify that there is only one subdirectory in the lib/modules directory of the image.

        The existence of more than one subdirectory indicates a mismatch between the kernel of the image and the DVS RPMS that were installed in the previous step.

        ```bash
        ncn-m001# la UAN-1.4.0-day-zero/lib/modules/
        total 8.0K
        drwxr-xr-x 3 root root   49 Feb 25 17:50 ./
        drwxr-xr-x 8 root root 4.0K Feb 25 17:52 ../
        drwxr-xr-x 6 root root 4.0K Mar 17 19:49 4.12.14-197.78_9.1.58-cray_shasta_c/  
        ```

    11. Resquash the new image directory.

        ```bash
        ncn-m001# mksquashfs UAN-1.4.0-day-zero UAN-1.4.0-day-zero.squashfs
        Parallel mksquashfs: Using 64 processors
        Creating 4.0 filesystem on UAN-1.4.0-day-zero.squashfs, block size 131072.
        ...  
        ```

    12. Create a new IMS image registration and save the id field in an environment variable.

        ```bash
        ncn-m001# cray ims images create --name UAN-1.4.0-day-zero
        name = "UAN-1.4.0-day-zero"
        created = "2021-03-17T20:23:05.576754+00:00"
        id = "ac31e971-f990-4b5f-821d-c0c18daefb6e"
        ncn-m001# export NEW_IMAGE_ID=ac31e971-f990-4b5f-821d-c0c18daefb6e  
        ```

    13. Upload the new image, initrd, and kernel to S3 using the id from the previous step.

        ```bash
        ncn-m001# cray artifacts create boot-images ${NEW_IMAGE_ID}/rootfs \
        UAN-1.4.0-day-zero.squashfs
        artifact = "ac31e971-f990-4b5f-821d-c0c18daefb6e/UAN-1.4.0-day-zero.rootfs"
        Key = "ac31e971-f990-4b5f-821d-c0c18daefb6e/UAN-1.4.0-day-zero.rootfs" 
<<<<<<< HEAD
        
=======
>>>>>>> c36c198 (STP-2624: added image management files)
        ncn-m001# cray artifacts create boot-images ${NEW_IMAGE_ID}/initrd \
        initrd
        artifact = "ac31e971-f990-4b5f-821d-c0c18daefb6e/UAN-1.4.0-day-zero.initrd"
        Key = "ac31e971-f990-4b5f-821d-c0c18daefb6e/UAN-1.4.0-day-zero.initrd" 
<<<<<<< HEAD
        
=======
>>>>>>> c36c198 (STP-2624: added image management files)
        ncn-m001# cray artifacts create boot-images ${NEW_IMAGE_ID}/kernel \
        vmlinuz
        artifact = "ac31e971-f990-4b5f-821d-c0c18daefb6e/UAN-1.4.0-day-zero.kernel"
        Key = "ac31e971-f990-4b5f-821d-c0c18daefb6e/UAN-1.4.0-day-zero.kernel" 
        ```

    14. Obtain the md5sum of the squashfs image, initrd, and kernel.

        ```bash
        ncn-m001# md5sum UAN-1.4.0-day-zero.squashfs initrd vmlinuz
        cb6a8934ad3c483e740c648238800e93  UAN-1.4.0-day-zero.squashfs
        3fd8a72a49a409f70140fabe11bdac25  initrd
        5edcf3fd42ab1eccfbf1e52008dac5b9  vmlinuz
        ```

    15. Use the image id from Step 1 to print out all the IMS details about the current UAN image.

        ```bash
        ncn-m001# cray ims images describe c880251d-b275-463f-8279-e6033f61578b
        created = "2021-03-24T18:00:24.464755+00:00"
        id = "c880251d-b275-463f-8279-e6033f61578b"
        name = "cray-shasta-uan-cos-sles15sp1.x86_64-0.1.32"[link]
        etag = "d4e09fb028d5d99e4a0d4d9b9d930e13"
        path = "s3://boot-images/c880251d-b275-463f-8279-e6033f61578b/manifest.json"
        type = "s3"
        ```

    16. Use the path of the manifest.json file to download that JSON to a local file. Omit everything before the image id in the cray artifacts get boot-images command, as shown in the following example what does this sentence even mean? should we cut it?.

        ```bash
        ncn-m001# cray artifacts get boot-images \
        c880251d-b275-463f-8279-e6033f61578b/manifest.json uan-manifest.json
        ncn-m001# cat uan-manifest.json
        {
            "artifacts": [
                {
                    "link": {
                        "etag": "6d04c3a4546888ee740d7149eaecea68",
                        "path": "s3://boot-images/c880251d-b275-463f-8279-e6033f61578b/rootfs",
                        "type": "s3"
                    },
                    "md5": "a159b94238fc5bfe80045889226b33a3",
                    "type": "application/vnd.cray.image.rootfs.squashfs"
                },
                {
                    "link": {
                        "etag": "6d04c3a4546888ee740d7149eaecea68",
                        "path": "s3://boot-images/c880251d-b275-463f-8279-e6033f61578b/kernel",
                        "type": "s3"
                    },
                    "md5": "175f0c1363c9e3a4840b08570a923bc5",
                    "type": "application/vnd.cray.image.kernel"
                },
                {
                    "link": {
                        "etag": "6d04c3a4546888ee740d7149eaecea68",
                        "path": "s3://boot-images/c880251d-b275-463f-8279-e6033f61578b/initrd",
                        "type": "s3"
                    },
                    "md5": "0094629e4da25226c75b113760eeabf7",
                    "type": "application/vnd.cray.image.initrd"
                }
            ],
            "created" : "20210317153136",
            "version": "1.0"
        }
        ```

        Alternatively, a mainfest.json can be created from scratch. In that case, create a new hexadecimal value for the `etag` if the image referred to by the manifest does not already have one. The `etag` field can not be left blank.

    17. Replace the path and md5 values of the initrd, kernel, and rootfs with the values obtained in substeps m and n.

    18. Update the value for the `"created"` line in the manifest with the output of the following command:

        ```bash
        ncn-m001# date '+%Y%m%d%H%M%S'
        ```

    19. Verify that the modified JSON file is still valid.

        ```bash
        ncn-m001# cat manifest.json | jq
        ```

    20. Save the changes to the file.

    21. Upload the updated manifest.json file.

        ```bash
        ncn-m001# cray artifacts create boot-images \
        ${NEW_IMAGE_ID}/manifest.json uan-manifest.json
        artifact = "ac31e971-f990-4b5f-821d-c0c18daefb6e/manifest.json"
        Key = "ac31e971-f990-4b5f-821d-c0c18daefb6e/manifest.json"  
        ```

    22. Update the IMS image to use the new uan-manifest.json file.

        ```bash
        ncn-m001# cray ims images update ${NEW_IMAGE_ID} \
        --link-type s3 --link-path s3://boot-images/${NEW_IMAGE_ID}/manifest.json \
        --link-etag 6d04c3a4546888ee740d7149eaecea68
        created = "2021-03-17T20:23:05.576754+00:00"
        id = "ac31e971-f990-4b5f-821d-c0c18daefb6e"
        name = "UAN-1.4.0-day-zero"
         
        [link]
        etag = "6d04c3a4546888ee740d7149eaecea68"
        path = "s3://boot-images/ac31e971-f990-4b5f-821d-c0c18daefb6e/manifest.json"
        type = "s3"  
        ```

17. Create a CFS session to perform preboot image customization of the UAN image.

    ```bash
    ncn-m001# cray cfs sessions create --name uan-config-PRODUCT_VERSION \
                      --configuration-name uan-config-PRODUCT_VERSION \
                      --target-definition image \
                      --target-group Application $NEW_IMAGE_ID \
                      --format json
    ```

18. Wait until the CFS configuration session for the image customization to complete. Then record the ID of the IMS image created by CFS.

    The following command will produce output while the process is running. If the CFS session completes successfully, an IMS image ID will appear in the output.

    ```bash
    ncn-m001# cray cfs sessions describe uan-config-PRODUCT_VERSION --format json | jq
    ```

<<<<<<< HEAD
### Prepare UAN Boot Session Templates

19. Retrieve the xnames of the UAN nodes from the Hardware State Manager \(HSM\).
=======
19. |PREPARE UAN BOOT SESSION TEMPLATES|

20. Retrieve the xnames of the UAN nodes from the Hardware State Manager \(HSM\).
>>>>>>> c36c198 (STP-2624: added image management files)

    These xnames are needed for Step 20.

    ```bash
    ncn-m001# cray hsm state components list --role Application --subrole UAN --format json | jq -r .Components[].ID
    x3000c0s19b0n0
    x3000c0s24b0n0
    x3000c0s20b0n0
    x3000c0s22b0n0
    ```

<<<<<<< HEAD
20. Determine the correct value for the ifmap option in the `kernel_parameters` string for the type of UAN.
=======
21. Determine the correct value for the ifmap option in the `kernel_parameters` string for the type of UAN.
>>>>>>> c36c198 (STP-2624: added image management files)

    -   Use ifmap=net0:nmn0,lan0:hsn0,lan1:hsn1 if the UANs are:
        -   Either HPE DL325 or DL385 server that have a single OCP PCIe card installed.
        -   Gigabyte servers that do not have additional PCIe network cards installed other than the built-in LOM ports.
    -   Use ifmap=net2:nmn0,lan0:hsn0,lan1:hsn1 if the UANs are:
        -   Either HPE DL325 or DL385 servers which have a second OCP PCIe card installed, regardless if it is being used or not.
        -   Gigabyte servers that have a PCIe network card installed in addition to the built-in LOM ports, regardless if it is being used or not.
<<<<<<< HEAD
21. Construct a JSON BOS boot session template for the UAN.
=======
22. Construct a JSON BOS boot session template for the UAN.
>>>>>>> c36c198 (STP-2624: added image management files)

    1.  Populate the template with the following information:

        -   The value of the ifmap option for the `kernel_parameters` string that was determined in the previous step.
        -   The xnames of Application nodes from Step 18
        -   The customized image ID from Step 17 for
        -   The CFS configuration session name from Step 17
    2.  Verify that the session template matches the format and structure in the following example:

        ```bash
        {
           "boot_sets": {
             "uan": {
               "boot_ordinal": 2,
               "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=360M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=nmn0:dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 ifmap=net2:nmn0,lan0:hsn0,lan1:hsn1 spire_join_token=${SPIRE_JOIN_TOKEN}",
               "network": "nmn",
               "node_list": [
                 # \[ ... List of Application Nodes from cray hsm state command ...\]
               ],
               "path": "s3://boot-images/IMS\_IMAGE\_ID/manifest.json",  # <-- result\_id from CFS image customization session
               "rootfs_provider": "cpss3",
               "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
               "type": "s3"
             }
           },
           "cfs": {
               "configuration": "uan-config-PRODUCT\_VERSION"
           },
           "enable_cfs": true,
           "name": "uan-sessiontemplate-PRODUCT\_VERSION"
         }
        ```

    3.  Save the template with a descriptive name, such as uan-sessiontemplate-PRODUCT\_VERSION.json.

<<<<<<< HEAD
22. Register the session template with BOS.
=======
23. Register the session template with BOS.
>>>>>>> c36c198 (STP-2624: added image management files)

    The following command uses the JSON session template file to save a session template in BOS. This step allows administrators to boot UANs by referring to the session template name.

    ```bash
    ncn-m001# cray bos sessiontemplate create \
                       --name uan-sessiontemplate-PRODUCT_VERSION \
                       --file uan-sessiontemplate-PRODUCT_VERSION.json
    /sessionTemplate/uan-sessiontemplate-PRODUCT_VERSION
    ```


Perform [Boot UANs](Boot_UANs.md) to boot the UANs with the new image and BOS session template.


