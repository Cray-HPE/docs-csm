# Create UAN Boot Images

Update configuration management Git repository to match the installed version of the [User Access Node (UAN)](../../glossary.md#user-access-node-uan) product.
Then use that updated configuration to create UAN boot images and a [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos) session template.

This is the overall workflow for preparing UAN images for booting UANs:

1. Clone the UAN configuration Git repository and create a branch based on the branch imported by the UAN installation.
1. Update the configuration content and push the changes to the newly created branch.
1. Create a [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs) configuration for the UANs, specifying the Git configuration and the
   UAN image to apply the configuration to. More Cray products can also be added to the CFS configuration so that the UANs can install multiple Cray products into the UAN image
   at the same time.
1. Configure the UAN image using CFS and generate a newly configured version of the UAN image.
1. Create a BOS boot session template for the UANs. This template maps the configured image, the CFS configuration to be applied post-boot, and
   the nodes which will receive the image and configuration.

Once the UAN BOS session template is created, then the UANs will be ready to be booted by a BOS session.

Replace `PRODUCT_VERSION` and `CRAY_EX_HOSTNAME` in the example commands in this procedure with the current UAN product version installed
\(see [1. Get UAN information](#1-get-uan-information)\) and the hostname of the HPE Cray EX system, respectively.

- [Prerequisites](#prerequisites)
- [Limitations](#limitations)
- [Procedure](#procedure)
  1. [Get UAN information](#1-get-uan-information)
  1. [UAN image pre-boot configuration](#2-uan-image-pre-boot-configuration)
  1. [Configure UAN images](#3-configure-uan-images)
  1. [Customize UAN image using CFS](#4-customize-uan-image-using-cfs)
  1. [Identify UAN xnames](#5-identify-uan-xnames)
  1. [Prepare UAN boot session templates](#6-prepare-uan-boot-session-templates)

## Prerequisites

The UAN product stream must be installed.

## Limitations

This guide only details how to apply UAN-specific configuration to the UAN image and nodes. Consult the manuals for the individual HPE products \(for example, workload managers
and the HPE Cray Programming Environment\) that must be configured on the UANs.

## Procedure

### 1. Get UAN information

<a name="get-uan-info"></a>Obtain UAN artifact IDs and other information.

Upon successful installation of the UAN product, the UAN configuration, image recipes, and prebuilt boot images are cataloged in the `cray-product-catalog` Kubernetes
ConfigMap. This information is required for this procedure.

Take note of the Gitea, Git, and [Image Management Service (IMS)](../../glossary.md#image-management-service-ims) values (highlighted in the example output below).

```bash
ncn-mw# kubectl get cm -n services cray-product-catalog -o json | jq -r .data.uan
```

Example output:

```yaml
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

### 2. UAN image pre-boot configuration

1. Generate the password hash for the `root` user.

    > Replace `PASSWORD` with the desired `root` password.
    > Do not omit the `-n` from the echo command. It is necessary to generate a valid hash.

    ```bash
    ncn-mw# echo -n PASSWORD | openssl passwd -6 -salt $(< /dev/urandom tr -dc ./A-Za-z0-9 | head -c4) --stdin
    ```

1. Obtain the HashiCorp Vault `root` token.

    ```bash
    ncn-mw# kubectl get secrets -n vault cray-vault-unseal-keys -o jsonpath='{.data.vault-root}' | base64 -d; echo
    ```

1. Write the password hash obtained from the `openssl` command to the HashiCorp Vault.

    1. Open a shell in the Vault pod.

        ```bash
        ncn-mw# kubectl exec -itn vault cray-vault-0 -- sh
        ```

    1. Authenticate with Vault.

        > The `vault login` command will request the `root` token found in the earlier step.

        ```bash
        cray-vault-0# export VAULT_ADDR=http://cray-vault:8200
        cray-vault-0# vault login
        ```

    1. Write the password hash to Vault.

        This password hash will be written to the UAN for the `root` user by CFS.

        > Replace `HASH` in the example below with the password hash obtained from the earlier step.

        ```bash
        cray-vault-0# vault write secret/uan root_password='HASH'
        ```

    1. Read back the password hash to verify that it was stored correctly.

        ```bash
        cray-vault-0# vault read secret/uan
        ```

    1. Exit from the Vault pod.

        ```bash
        cray-vault-0# exit
        ```

1. Obtain the password for the `crayvcs` user from the Kubernetes secret for use in the next command.

    ```bash
    ncn-mw# kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode
    ```

1. Clone the UAN configuration management repository.

    The repository is in the [Version Control Service (VCS)](../../glossary.md#version-control-service-vcs)/Gitea service, and its location is reported in the
    `cray-product-catalog` Kubernetes ConfigMap in the `configuration.clone_url` key.
    The `CRAY_EX_HOSTNAME` from the `clone_url` is replaced with `api-gw-service-nmn.local` in the command that clones the repository.

    ```bash
    ncn-mw# git clone https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
    ncn-mw# cd uan-config-management && git checkout cray/uan/PRODUCT_VERSION && git pull
    ```

1. Create a branch using the imported branch from the installation to customize the UAN image.

    This imported branch will be reported in the `cray-product-catalog` Kubernetes ConfigMap in the `configuration.import_branch` key under the UAN section.
    The format is `cray/uan/PRODUCT_VERSION`. In this guide, an `integration` branch is used for examples, but the name can be any valid Git branch name.

    Modifying the `cray/uan/PRODUCT_VERSION` branch that was created by the UAN product installation is not allowed by default.

    ```bash
    ncn-mw# git checkout -b integration && git merge cray/uan/PRODUCT_VERSION
    ```

1. Configure a `root` user in the UAN image.

    Add the encrypted password of the `root` user from `/etc/shadow` on an [Non-Compute Node (NCN)](../../glossary.md#non-compute-node-ncn) worker to the file `group_vars/Application/passwd.yml`.

    > Skip this step if the `root` user is already configured in the image.

    Hewlett Packard Enterprise recommends configuring a `root` user in the UAN image for troubleshooting purposes. The entry for `root` user password will resemble the following example:

    ```yaml
    root_passwd: $6$LmQ/PlWlKixK$VL4ueaZ8YoKOV6yYMA9iH0gCl8F4C/3yC.jMIGfOK6F61h6d.iZ6/QB0NLyex1J7AtOsYvqeycmLj2fQcLjfE1
    ```

1. Apply any site-specific customizations and modifications to the Ansible configuration for the UANs and commit the changes.

    The default Ansible play to configure UANs is `site.yml` in the base of the `uan-config-management` repository. The roles that are executed in this play allow for
    nondefault configuration as required for the system.

    Consult the individual Ansible role `README.md` files in the `uan-config-management` repository `roles` directory to configure individual role variables. Roles prefixed with
    `uan_` are specific to UAN configuration and include network interfaces, disk, LDAP, software packages, and message of the day roles.

    Variables should be defined and overridden in the Ansible inventory locations of the repository as shown in the following example and **not** in the Ansible plays and roles
    defaults. See [Ansible Directory Layout](https://docs.ansible.com/ansible/2.9/user_guide/playbooks_best_practices.html#directory-layout).

    > **WARNING:** Never place sensitive information such as passwords in the Git repository.

    The following example shows how to add a `vars.yml` file containing site-specific configuration values to the `Application` group variable location.

    These and other Ansible files do not necessarily need to be modified for UAN image creation.

    ```bash
    ncn-mw# vim group_vars/Application/vars.yml
    ncn-mw# git add group_vars/Application/vars.yml
    ncn-mw# git commit -m "Add vars.yml customizations"
    ```

1. Verify that the [System Layout Service (SLS)](../../glossary.md#system-layout-service-sls) and the `uan_interfaces` configuration role refer to the Mountain Node Management Network by the same name.

    > Skip this step if there are no [Mountain cabinets](../../glossary.md#mountain-cabinet) in the HPE Cray EX system.

    1. Edit the `roles/uan_interfaces/tasks/main.yml` file.

        Change the line that reads `url: http://cray-sls/v1/search/networks?name=MNMN` to read `url: http://cray-sls/v1/search/networks?name=NMN_MTN`.

        The following excerpt of the relevant section of the file shows the result of the change.

        ```yaml
        - name: Get Mountain NMN Services Network info from SLS
          local_action:
            module: uri
              url: http://cray-sls/v1/search/networks?name=NMN_MTN
            method: GET
          register: sls_mnmn_svcs
          ignore_errors: yes
        ```

    1. Stage and commit the network name change.

        ```bash
        ncn-mw# git add roles/uan_interfaces/tasks/main.yml
        ncn-mw# git commit -m "Add Mountain cabinet support"
        ```

1. Push the changes to the repository using the proper credentials, including the password obtained previously.

    ```bash
    ncn-mw# git push --set-upstream origin integration
    ```

    Enter the appropriate credentials when prompted:

    ```text
    Username for 'https://api-gw-service-nmn.local': crayvcs
    Password for 'https://crayvcs@api-gw-service-nmn.local':
    ```

1. Capture the most recent commit for reference in setting up a CFS configuration and navigate to the parent directory.

    ```bash
    ncn-mw# git rev-parse --verify HEAD
    ```

    `ecece54b1eb65d484444c4a5ca0b244b329f4667` is an example commit that could be returned.

1. Navigate back to the parent directory.

    ```bash
    ncn-mw# cd ..
    ```

The configuration parameters have been stored in a branch in the UAN Git repository. The next phase of the process is initiating the
Configuration Framework Service \(CFS\) to customize the image.

### 3. Configure UAN images

1. Create a JSON input file for generating a CFS configuration for the UAN.

    Gather the Git repository clone URL, commit, and top-level play for each configuration layer \(that is, Cray product\). Add them to the CFS configuration for the UAN, if wanted.

    For the commit value for the UAN layer, use the Git commit value obtained in the previous step.

    See the product manuals for further information on configuring other Cray products, as this procedure documents only the configuration of the UAN. More layers can be added
    to be configured in a single CFS session.

    The following configuration example can be used for preboot image customization as well as post-boot node configuration. This example contains only a single
    layer. However, configuration layers for other products may be specified in the list after this layer, if desired.

    ```json
    {
      "layers": [
        {
          "name": "uan-integration-PRODUCT_VERSION",
          "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
          "playbook": "site.yml",
          "commit": "ecece54b1eb65d484444c4a5ca0b244b329f4667"
        }        
      ]
    }
    ```

1. Add the configuration to CFS using the JSON input file.

    In the following example, the JSON file created in the previous step is named `uan-config-PRODUCT_VERSION.json`. Only the details for the UAN layer are shown.

    ```bash
    ncn-mw# cray cfs configurations update uan-config-PRODUCT_VERSION \
                      --file ./uan-config-PRODUCT_VERSION.json \
                      --format json
    ```

    Example output:

    > This output uses the example single-layer configuration from earlier. If layers were added for additional products, then they will also
    > appear in the output.

    ```json
    {
      "lastUpdated": "2021-07-28T03:26:00:37Z",
      "layers": [
        {
          "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
          "commit": "ecece54b1eb65d484444c4a5ca0b244b329f4667",
          "name": "uan-integration-PRODUCT_VERSION",
          "playbook": "site.yml"
        }
      ],
      "name": "uan-config-PRODUCT_VERSION"
    }
    ```

1. Modify the UAN image to include the `1.4.0` Day Zero RPMs.

    1. Expand the 1.4.0 Day Zero Patch tarball if it has not been done already.

        ```bash
        ncn-mw# tar -xvf shasta-1.4.0-p2.tar
        ```

        Example output:

        ```text
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

    1. Download the `rootfs` image specified in the UAN product catalog.

        Replace `IMAGE_ID` in the following export command with the IMS image ID recorded earlier in
        [1. Get UAN information](#1-get-uan-information).

        ```bash
        ncn-mw# UAN_IMAGE_ID=IMAGE_ID
        ncn-mw# cray artifacts get boot-images ${UAN_IMAGE_ID}/rootfs ${UAN_IMAGE_ID}.squashfs
        ncn-mw# ls -A ${UAN_IMAGE_ID}.squashfs
        ```

        Example output:

        ```text
        -rw-r--r-- 1 root root 1.5G Mar 17 19:35 f3ba09d7-e3c2-4b80-9d86-0ee2c48c2214.squashfs
        ```

    1. Mount the SquashFS file and copy its contents to a different directory.

        ```bash
        ncn-mw# mkdir mnt
        ncn-mw# mkdir UAN-1.4.0-day-zero
        ncn-mw# mount -t squashfs ${UAN_IMAGE_ID}.squashfs mnt -o ro,loop
        ncn-mw# cp -a mnt UAN-1.4.0-day-zero
        ncn-mw# umount mnt
        ncn-mw# rmdir mnt
        ```

    1. Copy the new RPMs into the new image directory.

        ```bash
        ncn-mw# cp 1.4.0-p2/rpms/* UAN-1.4.0-day-zero/
        ncn-mw# cd UAN-1.4.0-day-zero/
        ```

    1. `chroot` into the new image directory.

        ```bash
        ncn-mw# chroot . bash
        ```

    1. Update, erase, and install RPMs in the new image directory.

        ```bash
        chroot-ncn-mw# rpm -Uv cray-dvs-*.rpm
        chroot-ncn-mw# rpm -e cray-network-config
        chroot-ncn-mw# rpm -e slingshot-network-config-full
        chroot-ncn-mw# rpm -e slingshot-network-config
        chroot-ncn-mw# rpm -iv slingshot-network-config-full-1.1.7-20210318093253_83fab52-sles15sp1.x86_64.rpm \
                        slingshot-network-config-1.1.7-20210318093253_83fab52-sles15sp1.x86_64.rpm \
                        cray-network-config-1.1.7-20210318094806_b409053-sles15sp1.x86_64.rpm
        ```

    1. Generate a new `initrd` to match the updated image.

        Run the `/tmp/images.sh` script. Then wait for this script to complete before continuing.

        ```bash
        chroot-ncn-mw# /tmp/images.sh
        ```

        The output of this script will contain error messages. These error messages can be ignored as long as the following message appears at the end:
        `dracut: *** Creating initramfs image file`

    1. Copy the `/boot/initrd` and `/boot/vmlinuz` files out of the `chroot` environment and into a temporary location on the file system of the node.

    1. Exit the `chroot` environment and delete the packages.

        ```bash
        chroot-ncn-mw# exit
        ncn-mw# rm *.rpm
        ncn-mw# cd ..
        ```

    1. Verify that there is only one subdirectory in the `lib/modules` directory of the image.

        The existence of more than one subdirectory indicates a mismatch between the kernel of the image and the DVS RPMs that were installed in the previous step.

        ```bash
        ncn-mw# la UAN-1.4.0-day-zero/lib/modules/
        ```

        Example output:

        ```text
        total 8.0K
        drwxr-xr-x 3 root root   49 Feb 25 17:50 ./
        drwxr-xr-x 8 root root 4.0K Feb 25 17:52 ../
        drwxr-xr-x 6 root root 4.0K Mar 17 19:49 4.12.14-197.78_9.1.58-cray_shasta_c/
        ```

    1. Squash the new image directory.

        ```bash
        ncn-mw# mksquashfs UAN-1.4.0-day-zero UAN-1.4.0-day-zero.squashfs
        ```

        Example output:

        ```text
        Parallel mksquashfs: Using 64 processors
        Creating 4.0 filesystem on UAN-1.4.0-day-zero.squashfs, block size 131072.

        [...]
        ```

    1. Create a new IMS image registration and save the `id` field in an environment variable.

        ```bash
        ncn-mw# cray ims images create --name UAN-1.4.0-day-zero --format toml
        ```

        Example output:

        ```toml
        name = "UAN-1.4.0-day-zero"
        created = "2021-03-17T20:23:05.576754+00:00"
        id = "ac31e971-f990-4b5f-821d-c0c18daefb6e"
        ncn-mw# export NEW_IMAGE_ID=ac31e971-f990-4b5f-821d-c0c18daefb6e
        ```

    1. Upload the new image, `initrd`, and kernel to S3 using the ID from the previous step.

        1. Upload the image.

            ```bash
            ncn-mw# cray artifacts create boot-images ${NEW_IMAGE_ID}/rootfs UAN-1.4.0-day-zero.squashfs --format toml
            ```

            Example output:

            ```toml
            artifact = "ac31e971-f990-4b5f-821d-c0c18daefb6e/UAN-1.4.0-day-zero.rootfs"
            Key = "ac31e971-f990-4b5f-821d-c0c18daefb6e/UAN-1.4.0-day-zero.rootfs"
            ```

        1. Upload the `initrd`.

            ```bash
            ncn-mw# cray artifacts create boot-images ${NEW_IMAGE_ID}/initrd initrd --format toml
            ```

            Example output:

            ```toml
            artifact = "ac31e971-f990-4b5f-821d-c0c18daefb6e/UAN-1.4.0-day-zero.initrd"
            Key = "ac31e971-f990-4b5f-821d-c0c18daefb6e/UAN-1.4.0-day-zero.initrd"
            ```

        1. Upload the kernel.

            ```bash
            ncn-mw# cray artifacts create boot-images ${NEW_IMAGE_ID}/kernel vmlinuz --format toml
            ```

            Example output:

            ```toml
            artifact = "ac31e971-f990-4b5f-821d-c0c18daefb6e/UAN-1.4.0-day-zero.kernel"
            Key = "ac31e971-f990-4b5f-821d-c0c18daefb6e/UAN-1.4.0-day-zero.kernel"
            ```

    1. Get the S3 generated `etag` value for each uploaded artifact.

        1. Display S3 values for uploaded image.

            ```bash
            ncn-mw# cray artifacts describe boot-images ${NEW_IMAGE_ID}/rootfs --format toml
            ```

            Example output:

            ```toml
            [artifact]
            AcceptRanges = "bytes"
            LastModified = "2021-05-05T00:25:21+00:00"
            ContentLength = 1647050752
            ETag = "\"db5582fd817c8a8dc084e1b8b4f0ea3b-197\""  <---
            ContentType = "binary/octet-stream"

            [artifact.Metadata]
            md5sum = "cb6a8934ad3c483e740c648238800e93"
            ```

            Note that when adding the `etag` to the IMS manifest below, remove the quotation
            marks from the `etag` value. So, for the above artifact, the `etag` would be
            `db5582fd817c8a8dc084e1b8b4f0ea3b-197`.

        1. Display S3 values for uploaded `initrd`.

            ```bash
            ncn-mw# cray artifacts describe boot-images ${NEW_IMAGE_ID}/initrd
            ```

        1. Display S3 values for uploaded kernel.

            ```bash
            ncn-mw# cray artifacts describe boot-images ${NEW_IMAGE_ID}/kernel
            ```

    1. Obtain the `md5sum` of the SquashFS image, `initrd`, and kernel.

        ```bash
        ncn-mw# md5sum UAN-1.4.0-day-zero.squashfs initrd vmlinuz
        ```

        Example output:

        ```text
        cb6a8934ad3c483e740c648238800e93  UAN-1.4.0-day-zero.squashfs
        3fd8a72a49a409f70140fabe11bdac25  initrd
        5edcf3fd42ab1eccfbf1e52008dac5b9  vmlinuz
        ```

    1. Print out all the IMS details about the current UAN image.

        Use the IMS image ID from [1. Get UAN information](#1-get-uan-information).

        ```bash
        ncn-mw# cray ims images describe c880251d-b275-463f-8279-e6033f61578b --format toml
        ```

        Example output:

        ```toml
        created = "2021-03-24T18:00:24.464755+00:00"
        id = "c880251d-b275-463f-8279-e6033f61578b"
        name = "cray-shasta-uan-cos-sles15sp1.x86_64-0.1.32"

        [link]
        etag = "d4e09fb028d5d99e4a0d4d9b9d930e13"
        path = "s3://boot-images/c880251d-b275-463f-8279-e6033f61578b/manifest.json"
        type = "s3"
        ```

    1. Use the path of the `manifest.json` file to download that JSON to a local file.

        ```bash
        ncn-mw# cray artifacts get boot-images c880251d-b275-463f-8279-e6033f61578b/manifest.json uan-manifest.json
        ncn-mw# cat uan-manifest.json
        ```

        Example output:

        ```json
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

        Alternatively, a `manifest.json` can be created from scratch.

    1. Replace the `path`, `md5`, and `etag` values of the `initrd`, kernel, and `rootfs` with the values obtained in substeps above.

    1. Update the value for the `created` field in the manifest with the output of the following command:

        ```bash
        ncn-mw# date '+%Y%m%d%H%M%S'
        ```

    1. Verify that the modified JSON file is still valid.

        ```bash
        ncn-mw# cat manifest.json | jq
        ```

    1. Upload the updated `manifest.json` file.

        ```bash
        ncn-mw# cray artifacts create boot-images ${NEW_IMAGE_ID}/manifest.json uan-manifest.json
        ```

    1. Update the IMS image to use the new `uan-manifest.json` file.

        ```bash
        ncn-mw# cray ims images update ${NEW_IMAGE_ID} \
                --link-type s3 --link-path s3://boot-images/${NEW_IMAGE_ID}/manifest.json \
                --link-etag 6d04c3a4546888ee740d7149eaecea68 --format toml
        ```

        Example output:

        ```toml
        created = "2021-03-17T20:23:05.576754+00:00"
        id = "ac31e971-f990-4b5f-821d-c0c18daefb6e"
        name = "UAN-1.4.0-day-zero"

        [link]
        etag = "6d04c3a4546888ee740d7149eaecea68"
        path = "s3://boot-images/ac31e971-f990-4b5f-821d-c0c18daefb6e/manifest.json"
        type = "s3"
        ```

### 4. Customize UAN image using CFS

1. Create a CFS session to perform preboot image customization of the UAN image.

    ```bash
    ncn-mw# cray cfs sessions create --name uan-config-PRODUCT_VERSION \
            --configuration-name uan-config-PRODUCT_VERSION \
            --target-definition image \
            --target-group Application $NEW_IMAGE_ID \
            --format json
    ```

1. <a name="wait-for-cfs-session"></a>Wait for the CFS configuration session for the image customization to complete.

    Then record the ID of the IMS image created by CFS.

    The following command will produce output while the process is running. If the CFS session completes successfully, an IMS image ID will appear in the output.

    ```bash
    ncn-mw# cray cfs sessions describe uan-config-PRODUCT_VERSION --format json | jq
    ```

### 5. Identify UAN xnames

<a name="get-xnames"></a>Retrieve the [component names (xnames)](../../glossary.md#xname) of the UANs from the [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm).

```bash
ncn-mw# cray hsm state components list --role Application --subrole UAN --format json | jq -r .Components[].ID
```

Example output:

```text
x3000c0s19b0n0
x3000c0s24b0n0
x3000c0s20b0n0
x3000c0s22b0n0
```

### 6. Prepare UAN boot session templates

1. Determine the correct value for the `ifmap` option in the `kernel_parameters` string for the type of UAN.

    - Use `ifmap=net0:nmn0,lan0:hsn0,lan1:hsn1` if the UANs are:
      - Either HPE DL325 or DL385 nodes that have a single OCP PCIe card installed.
      - Gigabyte nodes that do not have additional PCIe network cards installed other than the built-in LOM ports.
    - Use `ifmap=net2:nmn0,lan0:hsn0,lan1:hsn1` if the UANs are:
      - Either HPE DL325 or DL385 nodes which have a second OCP PCIe card installed, regardless of if it is being used or not.
      - Gigabyte nodes that have a PCIe network card installed in addition to the built-in LOM ports, regardless of if it is being used or not.

1. Construct a JSON BOS boot session template for the UAN.

    1. Populate the template with the following information:

        - The value of the `ifmap` option for the `kernel_parameters` string that was determined in the previous step.
        - For the `node_list` in the boot set, use the xnames of the UANs found in [5. Identify UAN xnames](#5-identify-uan-xnames).
        - The `path` field in the boot set should contain the customized image IMS ID (`result_id`) from [4. Customize UAN image using CFS](#4-customize-uan-image-using-cfs).
        - The `cfs`.`configuration` field should be set to the name of the CFS configuration used in [4. Customize UAN image using CFS](#4-customize-uan-image-using-cfs).

    1. Verify that the session template matches the format and structure in the following example:

        ```json
        {
          "boot_sets": {
            "uan": {
              "boot_ordinal": 2,
              "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=360M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=nmn0:dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 ifmap=net2:nmn0,lan0:hsn0,lan1:hsn1 spire_join_token=${SPIRE_JOIN_TOKEN}",
              "network": "nmn",
              "node_list": [
                "#... List of Application Nodes from cray hsm state command ..."
              ],
              "path": "s3://boot-images/IMS_IMAGE_ID/manifest.json",
              "rootfs_provider": "cpss3",
              "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
              "type": "s3"
            }
          },
          "cfs": {
            "configuration": "uan-config-PRODUCT\_VERSION"
          },
          "enable_cfs": true
        }
        ```

    1. Save the template with a descriptive name, such as `uan-sessiontemplate-PRODUCT_VERSION.json`.

1. Register the session template with BOS.

    The following command uses the JSON session template file to save a session template in BOS. This step allows administrators to boot UANs by referring to the session template name.

    ```bash
    ncn-mw# cray bos sessiontemplate create \
            --name uan-sessiontemplate-PRODUCT_VERSION \
            --file uan-sessiontemplate-PRODUCT_VERSION.json
    ```

    Example output:

    ```text
    /sessionTemplate/uan-sessiontemplate-PRODUCT_VERSION
    ```

Perform [Boot UANs](../boot_orchestration/Boot_UANs.md) to boot the UANs with the new image and BOS session template.
